class Release < Thor
  def all(version)
    self.version(version)
    self.doc(version)
    self.tmbundle
    Gem.new.package
    self.gems
    self.tag(version)
  end

  def version(version)
    content = File.read("rango.gemspec")
    content.gsub!(/version = "\d+\.\d+\.\d+"/, "version = \"#{version}\"")
    File.open("rango.spec", "w") do |file|
      file.puts(content)
    end
    %x[git commit rango.gemspec -m "Version increased to #{version}."]
  end

  desc "doc", "Freeze documentation."
  def doc(version)
    Yardoc.new.generate
    %x[cp -R doc/head doc/#{version}]
    %x[git add doc/#{version}]
    %x[git commit doc/#{version} -m "Documentation for version #{version} freezed."]
  end

  desc "tag", "Create Git tag for this version"
  def tag(version)
    # TODO
  end

  desc "gems", "Propagate the gems to the RubyForge."
  def gems
    # TODO
  end
  
  desc "tmbundle", "Upgrade the TextMate bundle."
  def tmbundle
    %x[rm -rf support/Rango.tmbundle]
    %x[cp -R "#{ENV["HOME"]}/Library/Application\ Support/TextMate/Bundles/Rango.tmbundle" support/]
    %x[git add support/Rango.tmbundle]
    %x[git commit support/Rango.tmbundle -m "Updated Rango TextMate bundle."]
  end
end