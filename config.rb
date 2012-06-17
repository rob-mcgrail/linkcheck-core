# Configuration options
require 'ostruct'
$options = OpenStruct.new

$options.datastore = 1
$options.global_prefix = 'tki-linkcheck'
$options.valid_schemes = ['http', 'ftp', 'https']
$options.checked_classes = [URI::HTTP]
