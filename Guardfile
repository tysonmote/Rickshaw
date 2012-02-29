notification :growl

BUILD_FILE = "./public/rickshaw.js"

SOURCE_FILES = %w{
./src/Rickshaw.js.coffee
./src/Rickshaw.Model.js.coffee
./src/Rickshaw.List.js.coffee
./src/Rickshaw.Controllers.js.coffee
./src/Rickshaw.Views.js.coffee
./src/Rickshaw.Handlebars.js.coffee
./src/Rickshaw.Metamorph.js.coffee
}

def build_rickshaw
  if `coffee --join #{BUILD_FILE} --compile #{SOURCE_FILES.join(' ')} 2>&1` =~ /^Error:.+/
    Notifier.notify( $~.to_s.split("\n")[0], image: :failed )
  else
    Notifier.notify( "Compiled Rickshaw" )
  end
end

guard :shell do
  watch %r{src/.+\.coffee$} do
    build_rickshaw
  end
end

build_rickshaw
