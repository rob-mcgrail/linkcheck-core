# Configuration options
require 'ostruct'
$options = OpenStruct.new

$options.datastore = 1
$options.global_prefix = 'tki-linkcheck' # changing this will orphan hundreds of redis keys.
$options.valid_schemes = ['http', 'ftp', 'https']
$options.checked_classes = [URI::HTTP, URI::HTTPS]
$options.linkcache_time = 3600
$options.page_delay = 1
$options.retry_count = 2
$options.permanently_ignore = [/Search=true&filter\[\]=/, /^mailto:/]
