require "#{File.dirname(__FILE__)}/farhang"
map('/') {run Farhang::FarhangClient}
map('/edit') {run Farhang::FarhangEditor}
