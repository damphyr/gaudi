module TestHelpers
  def mock_system_configuration filename,lines
    fname=File.join(File.dirname(__FILE__),filename)
    File.stubs(:exist?).with(fname).returns(true)
    File.stubs(:readlines).with(fname).returns(lines)
    fname
  end
  def directory_fixture
    base=File.dirname(__FILE__)
    mkdir_p("#{base}/tmp/common/FOO/inc",:verbose=>false)
    mkdir_p("#{base}/tmp/mingw/FOO/test/b",:verbose=>false)
    touch("#{base}/tmp/mingw/FOO/foo.c",:verbose=>false)
    touch("#{base}/tmp/mingw/FOO/foop.cpp",:verbose=>false)
    touch("#{base}/tmp/mingw/FOO/bar.asm",:verbose=>false)
    touch("#{base}/tmp/mingw/FOO/test/f.c",:verbose=>false)
    touch("#{base}/tmp/mingw/FOO/test/f.cpp",:verbose=>false)
    touch("#{base}/tmp/mingw/FOO/test/f.h",:verbose=>false)
    touch("#{base}/tmp/mingw/FOO/test/b/b.c",:verbose=>false)
    touch("#{base}/tmp/mingw/FOO/foo.h",:verbose=>false)
    touch("#{base}/tmp/common/FOO/pub.c",:verbose=>false)
    touch("#{base}/tmp/common/FOO/pub.cpp",:verbose=>false)
    touch("#{base}/tmp/common/FOO/inc/pub.h",:verbose=>false)
    mkdir_p("#{base}/tmp/common/BAR",:verbose=>false)
    touch("#{base}/tmp/common/BAR/bar.c",:verbose=>false)    
    File.open("#{base}/tmp/common/BAR/build.cfg","wb"){|f| f.write(['prefix=BAR'].join("\n"))}
    File.open("#{base}/tmp/common/FOO/build.cfg","wb"){|f| f.write(['prefix=FOO','deps=BAR','incs= ./inc','libs= foo.lib,bar.lib'].join("\n"))}
    mkdir_p("#{base}/tmp/deployments/FOO/foo",:verbose=>false)
    File.open("#{base}/tmp/deployments/FOO/foo/Pinky.cfg","wb"){|f| f.write(['prefix=Pinky','deps=FOO'].join("\n"))}
    mkdir_p("#{base}/tmp/deployments/BAR/foo",:verbose=>false)
    File.open("#{base}/tmp/deployments/BAR/foo/Pinky.cfg","wb"){|f| f.write(['prefix=Pinky','deps=FOO'].join("\n"))}
    File.open("#{base}/tmp/deployments/BAR/foo/Brain.cfg","wb"){|f| f.write(['prefix=Pinky','deps=FOO'].join("\n"))}
    touch("#{base}/tmp/libs.yml",:verbose=>false)    
    File.open("#{base}/tmp/brain.cfg","wb"){|f| f.write(system_config_test_data.join("\n"))}
    File.open("#{base}/tmp/foo.cfg","wb"){|f| f.write(platform_config_test_data.join("\n"))}
    return "#{base}/tmp"
  end

  def platform_config_test_data
    ['source_extensions=.c,.cpp','header_extensions=.h','object_extension=.o', 'library_extension=.so','executable_extension=.e',
      'libs=','lib_cfg=libs.yml','compiler_options=-c','assembler_options=-a','library_options=-l','linker_options=-e'
    ]
  end

  def system_config_test_data
    ['base=.','out=out/','platforms=foo','foo=./foo.cfg',"sources=#{File.dirname(__FILE__)}/tmp/"]
  end
end