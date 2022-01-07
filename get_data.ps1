$OUT_DIR="data/good-pages"
$CAT_DIR="${OUT_DIR}/categories"
$SCRAP_DIR="${OUT_DIR}/scrapped"
$HTML_DIR="${SCRAP_DIR}/html"
$PAGES_DIR="${SCRAP_DIR}/pages"
$WIKIDATA_DUMP_PATH="../wikiEL/dumps/wikidata-20211101-all.json.bz2"

# Create outputs directories
foreach ($dir in $OUT_DIR,$CAT_DIR,$SCRAP_DIR,$HTML_DIR,$PAGES_DIR) {
    if (!(Test-Path $dir)) {
        New-Item $dir -ItemType "directory"
    }
}

# Download pywikibot
if (!(Test-Path "core")) {
    git clone --recursive --branch stable --depth 1 https://gerrit.wikimedia.org/r/pywikibot/core.git
}

# Copy pywikibot config and custom scripts to the relevant locatinons
Copy-Item user-config.py core

# Download pages listing good and featured articles
python core/pwb.py listpages -cat:Wikipédia:Bons_articles/Justification_de_leur_promotion -save:$CAT_DIR
python core/pwb.py listpages -cat:Catégorie:Wikipédia:Articles_de_qualité/Justification_de_leur_promotion -save:$CAT_DIR

# Build a file listing titles of good and featured articles
python list_good_pages.py "$CAT_DIR" "$OUT_DIR/list-good-pages.txt"

# Get the list of all pages to download by extracting links from good pages
python get_pages_list.py "$OUT_DIR/list-good-pages.txt" "$OUT_DIR/list-all-pages.txt" "$OUT_DIR/list-all-pages.csv" $HTML_DIR --compress gzip

# Download html pages
python download_html_pages.py "$OUT_DIR/list-all-pages.csv" "$SCRAP_DIR/all-pages-paths.csv" "$SCRAP_DIR/all-pages-paths-errors.csv" $HTML_DIR --compress gzip

# Clean html pages
python clean_html_pages.py "$SCRAP_DIR/all-pages-paths.csv" $PAGES_DIR "$SCRAP_DIR/frwiki.csv" "$SCRAP_DIR/frwiki-errors.csv" --compress gzip

# Retrieve Wikidata properties for each page
python getwikidatapropertiesfromdump.py $WIKIDATA_DUMP_PATH "$SCRAP_DIR/frwiki.csv" "$SCRAP_DIR/wikidata.csv"

# Build the final dataset
python build_final_dataset.py "$SCRAP_DIR/frwiki.csv" "$SCRAP_DIR/wikidata.csv" "$SCRAP_DIR/final-dataset.csv"