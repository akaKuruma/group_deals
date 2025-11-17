const puppeteer = require('puppeteer');
const { Pool } = require('pg');
const fs = require('fs');
const path = require('path');

async function main() {
  const gapDataFetchId = process.argv[2];
  
  if (!gapDataFetchId) {
    console.error('Usage: node fetch_pages.js <gap_data_fetch_id>');
    process.exit(1);
  }
  
  // Connect to database using postgres:// connection string
  // The pg library handles postgres:// URLs directly
  const dbUrl = process.env.DATABASE_URL;
  
  if (!dbUrl) {
    console.error('DATABASE_URL environment variable is required');
    process.exit(1);
  }
  
  // Convert ecto:// to postgres:// format if needed
  let postgresUrl = dbUrl;
  if (dbUrl.startsWith('ecto://')) {
    // Convert ecto://USER:PASS@HOST:PORT/DATABASE to postgres://USER:PASS@HOST:PORT/DATABASE
    postgresUrl = dbUrl.replace(/^ecto:/, 'postgres:');
  }
  
  const pool = new Pool({
    connectionString: postgresUrl
  });
  
  try {
    // Get pending product data records
    const result = await pool.query(
      `SELECT 
         gpd.id,
         gpd.product_page_url,
         gpd.folder_timestamp,
         gp.cc_id,
         gp.product_folder_path
       FROM gap_product_data gpd
       JOIN gap_products gp ON gpd.product_id = gp.id
       WHERE gpd.gap_data_fetch_id = $1 
         AND gpd.page_fetch_status = 'pending'
         AND gpd.product_page_url IS NOT NULL
       ORDER BY gpd.inserted_at ASC`,
      [gapDataFetchId]
    );
    
    const products = result.rows;
    
    if (products.length === 0) {
      console.log('No pending pages to download');
      await pool.end();
      process.exit(0);
    }
    
    console.log(`Found ${products.length} pages to download`);
    
    // Launch browser
    const browser = await puppeteer.launch({
      headless: true,
      args: ['--no-sandbox', '--disable-setuid-sandbox'] // For Docker
    });
    
    const browserPage = await browser.newPage();
    
    // Set a reasonable timeout
    browserPage.setDefaultNavigationTimeout(60000);
    
    // Set user agent to avoid detection
    await browserPage.setUserAgent(
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36'
    );
    
    let successCount = 0;
    let failCount = 0;
    
    // Process each product
    for (const product of products) {
      try {
        console.log(`Fetching: ${product.product_page_url}`);
        
        await browserPage.goto(product.product_page_url, {
          waitUntil: 'networkidle0',
          timeout: 40000
        });
        
        // Wait a bit for any dynamic content
        await new Promise(resolve => setTimeout(resolve, 2000));
        
        const html = await browserPage.content();
       
        // Folder path
        const folderPath = product.product_folder_path;

        // File name
        const fileName = `${product.cc_id}_${product.folder_timestamp}.html`;

        // Build file path
        const filePath = path.join(folderPath, fileName);
        
        if (filePath) {
          // Ensure folder exists
          fs.mkdirSync(folderPath, { recursive: true });

          // Write file
          fs.writeFileSync(filePath, html);
        } else {
          throw new Error(`Missing product folder path for product ${product.cc_id}`);
        }
        
        // Update database: mark as succeeded
        await pool.query(
          `UPDATE gap_product_data
           SET page_fetch_status = 'succeeded',
               html_file_path = $1,
               updated_at = NOW()
           WHERE id = $2`,
          [filePath, product.id]
        );
        
        successCount++;
        console.log(`✓ Success: ${product.cc_id}`);
        
        // Small delay between requests to avoid rate limiting
        await new Promise(resolve => setTimeout(resolve, 2000));
        
      } catch (error) {
        console.error(`✗ Failed: ${product.cc_id} - ${error.message}`);
        
        // Update database: mark as failed
        await pool.query(
          `UPDATE gap_product_data
           SET page_fetch_status = 'failed',
               updated_at = NOW()
           WHERE id = $1`,
          [product.id]
        );
        
        failCount++;
      }
    }
    
    await browser.close();
    await pool.end();
    
    console.log(`\nCompleted: ${successCount} succeeded, ${failCount} failed`);
    process.exit(0);
    
  } catch (error) {
    console.error('Fatal error:', error);
    await pool.end();
    process.exit(1);
  }
}

main();

