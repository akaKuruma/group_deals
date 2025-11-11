# Gap Data Fetch Workflow Plan

## Workflow Overview

```
FetchWorkflowCoordinator (manages the entire workflow)
  ├── FetchGapPageJsonWorker (for each GapPage) - SEQUENTIAL
  │     ├─── FetchProductPageWorker (for each product in JSON) - SEQUENTIAL
  │     │     └── ParseProductPageWorker (parse HTML) - PARALLEL
  │     └── FetchProductImagesWorker (fetch images) - SEQUENTIAL
  └── GenerateSqlWorker (final step, triggered when all done)
```

## (Plan Step 1)User Interface

### PagesGroup Index Page
- Add "Fetch Data" button in table actions column
- Button must be disabled if an active fetch process exists for that PagesGroup
- Active fetch = status not in [:failed, :succeeded]

### PagesGroup Show Page
- Add "Fetch Data" button in header actions
- Button must be disabled if an active fetch process exists for that PagesGroup
- Active fetch = status not in [:failed, :succeeded]

## Button Action Flow

1. Check if active fetch exists for PagesGroup (status not in [:failed, :succeeded])
2. If active, show error flash message and disable button
3. If not active:
   - Create GapDataFetch entity with status: :pending (blocks button immediately)
   - Generate timestamp: {YYYYMMDDHHMMSS}
   - Store timestamp in GapDataFetch.folder_timestamp
   - Schedule first Oban job: `FetchGapPageJsonWorker.new(%{gap_data_fetch_id: id, folder_timestamp: timestamp})`

## Job Workflow Details

### (Plan Step 2)Job 1: FetchGapPageJsonWorker (SEQUENTIAL - one HTTP request at a time)

**Status Transition:** :pending → :fetching_product_list

1. Create folder: `tmp/{pages_group_id}/{YYYYMMDDHHMMSS}/` (using timestamp from job args)
2. Update GapDataFetch:
   - status: :fetching_product_list
   - started_at: current timestamp
3. For each GapPage in PagesGroup (process sequentially, one HTTP request at a time):
   - Call Gap API (api_url) using Req library
   - Handle response:
     - **If error:** mark GapDataFetch as :failed, set error_message, terminate process
     - **If success:** parse JSON response
4. Extract products array from JSON response
5. For each product (ccId) in the response:
   - Create/update Product record:
     - `style_id` (from API)
     - `cc_id` (unique identifier, from API)
     - `style_name`, `cc_name`, and other fields
   - Create ProductData record:
     - Link to Product (product_id)
     - Link to GapDataFetch (gap_data_fetch_id)
     - Store folder_timestamp
     - Extract and store image paths from API response in `api_image_paths` field (for later download in Job 4)
6. Update GapDataFetch:
   - total_pages: count of GapPages processed
   - processed_pages: increment for each page
   - total_products: count of all products found
7. If all pages processed successfully:
   - Schedule Job 2: `FetchProductPagesWorker.new(%{gap_data_fetch_id: id})`

**Important:** Only one HTTP request at a time. Process each GapPage sequentially.

---

### (Plan Step 3) Job 2: FetchProductPagesWorker (SEQUENTIAL - one HTTP request at a time)

**Status Transition:** :fetching_product_list → :fetching_product_page

1. Update GapDataFetch status to :fetching_product_page
2. For each ProductData in this fetch (process sequentially, one HTTP request at a time):
   - Get Product record to retrieve cc_id
   - Build product web page URL:
     - Base: `https://www.gapfactory.com/browse/product.do`
     - Parameter: `pid={cc_id}` (cc_id is the product identifier)
   - Fetch HTML page using Req library
   - Save HTML to: `tmp/{pages_group_id}/{timestamp}/{ccId}.html`
   - Update ProductData:
     - html_file_path: path to saved HTML file
   - Update GapDataFetch:
     - processed_products: increment counter
3. When all products fetched:
   - Schedule Job 3: `ParseProductPagesWorker.new(%{gap_data_fetch_id: id})`

**Important:** Only one HTTP request at a time. Process each product page sequentially.

---

### (Plan Step 4) Job 3: ParseProductPagesWorker (PARALLEL - can process multiple pages concurrently)

**Status:** Keep current status (:fetching_product_page) or add :parsing_product_pages if needed

1. For each saved product page HTML (can process in parallel):
   - Read HTML file from ProductData.html_file_path
   - Parse HTML to extract:
     - **Sizes:** available size options
     - **Models:** product model/variant information
     - **Colors:** color variants and availability
     - **Availability:** stock status per size/color
     - **Discounts:** pricing and discount information
   - Update ProductData:
     - parsed_data: map containing all extracted information
   - Update GapDataFetch:
     - processed_products: track parsing progress (if needed)
2. When all products parsed:
   - Schedule Job 4: `FetchProductImagesWorker.new(%{gap_data_fetch_id: id})`

**Important:** This job can run in parallel. Multiple product pages can be parsed concurrently.

---

### (Plan Step 5) Job 4: FetchProductImagesWorker (SEQUENTIAL - one HTTP request at a time)

**Status Transition:** :fetching_product_page → :fetching_product_image

1. Update GapDataFetch status to :fetching_product_image
2. For each ProductData in this fetch (process sequentially):
   - Get image paths from ProductData.api_image_paths (stored from Job 1 API response)
   - Create product-specific folder: `tmp/{pages_group_id}/{timestamp}/{product_ccId}/images/`
   - For each image (process sequentially, one HTTP request at a time):
     - Download image using Req library
     - Save to: `tmp/{pages_group_id}/{timestamp}/{product_ccId}/images/{image_filename}`
   - Update ProductData:
     - image_paths: array of saved image file paths
   - Update GapDataFetch:
     - processed_images: increment counter
3. When all images downloaded:
   - Update status to :generating_output
   - Schedule Job 5: `GenerateSqlWorker.new(%{gap_data_fetch_id: id})`

**Important:** 
- Only one HTTP request at a time
- Images are organized per product: `tmp/{pages_group_id}/{timestamp}/{product_ccId}/images/{image_filename}`

---

### (Plan Step 6) Job 5: GenerateSqlWorker (Final Step)

**Status Transition:** :generating_output → :succeeded

1. Update GapDataFetch status to :generating_output
2. Generate SQL output from all collected data:
   - Products (from Job 1)
   - Parsed product data (from Job 3)
   - Image paths (from Job 4)
3. When complete:
   - Update GapDataFetch:
     - status: :succeeded
     - completed_at: current timestamp

---

## Database Schemas

### GapDataFetch
- `pages_group_id` (belongs_to PagesGroup)
- `status` (Ecto.Enum): [:pending, :failed, :fetching_product_list, :fetching_product_page, :fetching_product_image, :generating_output, :succeeded]
- `current_step` (:string) - optional, for detailed tracking
- `total_pages` (:integer, default: 0)
- `processed_pages` (:integer, default: 0)
- `total_products` (:integer, default: 0)
- `processed_products` (:integer, default: 0)
- `total_images` (:integer, default: 0)
- `processed_images` (:integer, default: 0)
- `error_message` (:string)
- `error_details` (:map)
- `started_at` (:utc_datetime)
- `completed_at` (:utc_datetime)
- `folder_timestamp` (:string) - stores {YYYYMMDDHHMMSS}
- Unique constraint: only one active fetch per pages_group (status not in [:failed, :succeeded])

### Product
- `style_id` (:string) - Gap style identifier
- `cc_id` (:string) - Gap color code identifier (unique per product)
- `style_name` (:string)
- `cc_name` (:string) - color name
- Unique index on [:style_id, :cc_id]

### ProductData
- `product_id` (belongs_to Product)
- `gap_data_fetch_id` (belongs_to GapDataFetch)
- `folder_timestamp` (:string) - {YYYYMMDDHHMMSS}
- `api_image_paths` (:array, of: :string) - image paths from API response (stored in Job 1)
- `html_file_path` (:string) - path to saved HTML file
- `parsed_data` (:map) - sizes, models, colors, availability, discounts
- `image_paths` (:array, of: :string) - array of downloaded image file paths (stored in Job 4)

## Key Implementation Notes

1. **Sequential Processing:** Jobs 1, 2, and 4 must process HTTP requests sequentially (one at a time)
2. **Parallel Processing:** Job 3 (parsing) can run in parallel
3. **Error Handling:** If Job 1 API calls fail, mark as :failed and terminate entire process
4. **Status Management:** Status :pending immediately blocks the button when created
5. **Folder Structure:**
   - Base: `tmp/{pages_group_id}/{timestamp}/`
   - HTML files: `tmp/{pages_group_id}/{timestamp}/{ccId}.html`
   - Images: `tmp/{pages_group_id}/{timestamp}/{product_ccId}/images/{image_filename}`
6. **Product Identification:** Each ccId/sku is a separate product
7. **Variable Data:** ProductData entity stores variable data per fetch process
8. **Single Active Job:** Only one active fetch (status not in [:failed, :succeeded]) can exist per PagesGroup
