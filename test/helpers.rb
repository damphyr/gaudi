module TestHelpers
  def mock_configuration filename,lines
    fname=File.join(File.dirname(__FILE__),filename)
    File.expects(:exists?).with(fname).returns(true)
    File.expects(:readlines).with(fname).returns(lines)
    fname
  end
  def directory_fixture
    base=File.dirname(__FILE__)
    mkdir_p("#{base}/tmp/common/FOO/inc",:verbose=>false)
    mkdir_p("#{base}/tmp/mingw/FOO/test",:verbose=>false)
    touch("#{base}/tmp/mingw/FOO/foo.c",:verbose=>false)
    touch("#{base}/tmp/mingw/FOO/foop.cpp",:verbose=>false)
    touch("#{base}/tmp/mingw/FOO/bar.asm",:verbose=>false)
    touch("#{base}/tmp/mingw/FOO/test/f.c",:verbose=>false)
    touch("#{base}/tmp/mingw/FOO/test/f.cpp",:verbose=>false)
    touch("#{base}/tmp/mingw/FOO/foo.h",:verbose=>false)
    touch("#{base}/tmp/common/FOO/pub.c",:verbose=>false)
    touch("#{base}/tmp/common/FOO/pub.cpp",:verbose=>false)
    touch("#{base}/tmp/common/FOO/inc/pub.h",:verbose=>false)
    mkdir_p("#{base}/tmp/common/BAR",:verbose=>false)
    touch("#{base}/tmp/common/BAR/bar.c",:verbose=>false)    
    File.open("#{base}/tmp/common/BAR/build.cfg","wb"){|f| f.write(['prefix=BAR'].join("\n"))}
    File.open("#{base}/tmp/common/FOO/build.cfg","wb"){|f| f.write(['prefix=FOO','deps=BAR','incs= ./inc','libs= foo.lib,bar.lib'].join("\n"))}
    return "#{base}/tmp"
  end
end