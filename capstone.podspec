Pod::Spec.new do |s|
  s.name         = "capstone"
  s.version      = "3.0.5"
  s.summary      = "Capstone disassembly/disassembler framework"
  s.homepage     = "https://www.capstone-engine.org"
  s.license      = { :type => "BSD", :file => "LICENSE.TXT" }
  s.author       = { "Nguyen Anh Quynh" => "aquynh@gmail.com" }
  s.source       = { :git => "https://github.com/aquynh/capstone.git", :tag => "3.0.5" }
  
  {
    'AArch64' => 'ARM64',
    'ARM' => 'ARM',
    'EVM' => 'EVM',
    'M68K' => 'M68K',
    'M680X' => 'M680X',
    'Mips' => 'MIPS',
    'PowerPC' => 'POWERPC',
    'Sparc' => 'SPARC',
    'SystemZ' => 'SYSZ',
    'TMS320C64x' => 'TMS320C64X',
    'X86' => 'X86',
    'XCore' => 'XCORE'
  }.each do |arch, flag|
    s.subspec arch do |sp|
      sp.source_files = "arch/#{arch}/*.{h,c,inc}", "cs.c", "cs_priv.h", "{LEB128,MathExtras,MCDisassembler,MCFixedLenDisassembler}.h", "{MCInst,MCInstrDesc,MCRegisterInfo,SStream,utils}.{c,h}", "arch/*/*Module.h", "include/*.h"
      sp.public_header_files = "arch/#{arch}/*.h", "include/*.h"
      sp.compiler_flags = "-DCAPSTONE_HAS_#{flag}=1", "-DCAPSTONE_USE_SYS_DYN_MEM=1"
    end
  end
  
end
