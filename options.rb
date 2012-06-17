# Configuration options
require 'ostruct'
$options = OpenStruct.new

$options.datastore = 1
$options.global_prefix = 'tki-linkcheck' # changing this will orphan hundreds of redis keys.
$options.valid_schemes = ['http', 'ftp', 'https']
$options.checked_classes = [URI::HTTP, URI::HTTPS]
$options.linkcache_time = 3600
$options.crawl_delay = 0.5
$options.check_delay = 0.5
$options.retry_count = 1
$options.permanently_ignore = [ ]
$options.permanently_ignore << /Search=true&filter\[\]=/ #search
$options.permanently_ignore << /^mailto:/ #mailto
$options.permanently_ignore << /\);\s?$/ #href javascript
$options.permanently_ignore << /javascript:/ #href javascript
$options.permanently_ignore << /\/(e|m|r)\// #legacy
$options.permanently_ignore << /www\.tki\.org\.nz\/(about|contact|help|accessibility|privacy)(\/|$)/ # footer
$options.permanently_ignore << /\/wws\/arc\//
$options.crawl_limit = 1500 # maximum limit of pages to crawl for one site... emergency protection against loops...
