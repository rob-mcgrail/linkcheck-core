# Configuration options
require 'ostruct'
$options = OpenStruct.new

$options.datastore = 1
$options.global_prefix = 'tki-linkcheck' # changing this will orphan hundreds of redis keys.
                                         # if the db has been used for linkchecking, try cleaning it ala:
                                         # $ redis-cli KEYS "oldprefix*" | xargs redis-cli DEL
$options.valid_schemes = ['http', 'ftp', 'https']
$options.checked_classes = [URI::HTTP, URI::HTTPS]
$options.linkcache_time = 3600
$options.page_delay = 1
