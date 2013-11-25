module TestHelpers
  def mock_configuration filename,lines
    fname=File.join(File.dirname(__FILE__),filename)
    File.expects(:exists?).with(fname).returns(true)
    File.expects(:readlines).with(fname).returns(lines)
    fname
  end
  def directory_fixture
    base=File.dirname(__FILE__)
    mkdir_p("#{base}/tmp/common/Foo/inc",:verbose=>false)
    mkdir_p("#{base}/tmp/mingw/Foo/test",:verbose=>false)
    touch("#{base}/tmp/mingw/Foo/foo.c",:verbose=>false)
    touch("#{base}/tmp/mingw/Foo/foop.cpp",:verbose=>false)
    touch("#{base}/tmp/mingw/Foo/bar.asm",:verbose=>false)
    touch("#{base}/tmp/mingw/Foo/test/f.c",:verbose=>false)
    touch("#{base}/tmp/mingw/Foo/test/f.cpp",:verbose=>false)
    touch("#{base}/tmp/mingw/Foo/foo.h",:verbose=>false)
    touch("#{base}/tmp/common/Foo/pub.c",:verbose=>false)
    touch("#{base}/tmp/common/Foo/pub.cpp",:verbose=>false)
    touch("#{base}/tmp/common/Foo/inc/pub.h",:verbose=>false)
    mkdir_p("#{base}/tmp/common/Bar",:verbose=>false)
    touch("#{base}/tmp/common/Bar/bar.c",:verbose=>false)    
    File.open("#{base}/tmp/common/Bar/build.cfg","wb"){|f| f.write(['prefix=BAR'].join("\n"))}
    File.open("#{base}/tmp/common/Foo/build.cfg","wb"){|f| f.write(['prefix=FOO','deps=BAR','incs= ./inc','libs= foo.lib,bar.lib'].join("\n"))}
    return "#{base}/tmp"
  end
end