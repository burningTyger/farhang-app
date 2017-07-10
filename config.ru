require "#{File.dirname(__FILE__)}/farhang"
map('/') {run Farhang::Farhang}
map('/edit') {run Farhang::FarhangEditor}
