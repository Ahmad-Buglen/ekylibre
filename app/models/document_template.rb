# -*- coding: utf-8 -*-
# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier, Thibaud Merigon
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see http://www.gnu.org/licenses.
#
# == Table: document_templates
#
#  active       :boolean          not null
#  archiving    :string(63)       not null
#  by_default   :boolean          not null
#  created_at   :datetime         not null
#  creator_id   :integer
#  formats      :string(255)
#  id           :integer          not null, primary key
#  language     :string(3)        not null
#  lock_version :integer          default(0), not null
#  managed      :boolean          not null
#  name         :string(255)      not null
#  nature       :string(63)       not null
#  updated_at   :datetime         not null
#  updater_id   :integer
#

# Sources are stored in private/document_templates/:id/content.xml
class DocumentTemplate < Ekylibre::Record::Base
  # attr_accessible :active, :archiving, :by_default, :language, :name, :nature, :managed, :source, :formats
  enumerize :archiving, :in => [:none_of_template, :first_of_template, :last_of_template, :all_of_template, :none, :first, :last, :all], :default => :none, :predicates => {:prefix => true}
  enumerize :nature, :in => Nomen::DocumentNatures.all, :predicates => {:prefix => true}
  has_many :document_archives, :foreign_key => :template_id, :dependent => :nullify
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_length_of :language, :allow_nil => true, :maximum => 3
  validates_length_of :archiving, :nature, :allow_nil => true, :maximum => 63
  validates_length_of :formats, :name, :allow_nil => true, :maximum => 255
  validates_inclusion_of :active, :by_default, :managed, :in => [true, false]
  validates_presence_of :archiving, :language, :name, :nature
  #]VALIDATORS]
  validates_inclusion_of :nature, :in => self.nature.values

  has_default :scope => :nature

  # default_scope order(:name)
  scope :of_nature, lambda { |nature|
    raise ArgumentError.new("Unknown nature for a DocumentTemplate (got #{nature.inspect}:#{nature.class})") unless self.nature.values.include?(nature.to_s)
    where(:nature => nature.to_s, :active => true).order(:name)
  }

  protect(:on => :destroy) do
    self.document_archives.count <= 0
  end

  before_validation do
    # Check that given formats are all known
    unless self.formats.empty?
      self.formats = self.formats.to_s.downcase.strip.split(/[\s\,]+/).delete_if do |f|
        !Ekylibre::Reporting.formats.include?(f)
      end.join(", ")
    end
  end

  after_save do
    # Install file after save only
    if @source
      FileUtils.mkdir_p(self.source_path.dirname)
      File.open(self.source_path, "wb") do |f|
        # Updates source to make it working
        document = Nokogiri::XML(@source) do |config|
          config.noblanks.nonet.strict
        end
        if document.root and document.root.namespace and document.root.namespace.href == "http://jasperreports.sourceforge.net/jasperreports"
          # raise document.root.inspect if self.nature == "sales_invoice"
          if template = document.root.xpath('xmlns:template').first
            logger.info "NOTICE: Update <template> for document template #{self.nature}"
            template.children.remove
            template.add_child(Nokogiri::XML::CDATA.new(document, Rails.root.join("config", "corporate-identity", "reports-style.xml").relative_path_from(self.source_path.dirname).to_s.inspect))
          else
            logger.info "WARNING: Cannot find and update <template> in document template #{self.nature}"
          end
        end

        # Write source
        # f.write(@source.read)
        f.write(document.to_s)
      end
    end
  end

  # Updates archiving methods of other templates of same nature
  after_save do
    if self.archiving.to_s =~ /\_of\_template$/
      self.class.where("nature = ? AND NOT archiving LIKE ? AND id != ?", self.nature, "%_of_template", self.id).update_all("archiving = archiving || '_of_template'")
    else
      self.class.where("nature = ? AND id != ?", self.nature, self.id).update_all(:archiving => self.archiving)
    end
  end

  # Always after protect on destroy
  after_destroy do
    if self.source_dir.exist?
      FileUtils.rm_rf(self.source_dir)
    end
  end

  # Install the source of a document template
  # with all its dependencies
  def source=(file)
    @source = file
  end

  # Returns source value
  def source
    @source
  end

  # Returns the expected dir for the source file
  def source_dir
    return self.class.sources_root.join(self.id.to_s)
  end

  # Returns the expected path for the source file
  def source_path
    return self.source_dir.join("content.xml")
  end

  # Print document with default active template for the given nature
  # Returns nil if no template found.
  def self.print(nature, datasource, key, format = :pdf, options = {})
    if template = self.where(:nature => nature, :by_default => true, :active => true).first
      return template.print(datasource, key, format, options)
    end
    return nil
  end

  # Print a document with the given datasource
  # Store if needed by template
  # @param datasource XML representation of data used by the template
  def print(datasource, key, format = :pdf, options = {})
    # Load the report
    report = Beardley::Report.new(self.source_path)
    # Call it with datasource
    data = report.send("to_#{format}", datasource)
    # Archive the document according to archiving method. See #archive method.
    self.archive(data, key, format, options)
    # Returns only the data (without filename)
    return data
  end

  # Returns the list of formats of the templates
  def formats
    (self["formats"].blank? ? Ekylibre::Reporting.formats : self["formats"].strip.split(/[\s\,]+/))
  end

  def formats=(value)
    self["formats"] = (value.is_a?(Array) ? value.join(", ") : value.to_s)
  end

  # Archive the document using the given archiving method
  def archive(data, key, format, options = {})
    document = nil
    unless self.archiving_none? or self.archiving_none_of_template?
      # Find exisiting document
      document = Document.where(:nature => self.nature, :key => key).first
      # Create document if not exist
      document ||= Document.create!(:nature => self.nature, :key => key, :name => (options[:name] || tc('document_name', :nature => self.nature.text, :key => key))) # }, :without_protection => true)

      # Removes old archives if only keepping last archive
      if self.archiving_last? or self.archiving_last_of_template?
        filter = ["template_id IS NOT NULL AND document_id = ?", document.id]
        if self.archiving_last_of_template?
          filter[0] << " AND template_id = ?"
          filter << self.id
        end
        DocumentArchive.destroy_all(filter)
      end

      # Adds the new archive if expected
      if (self.archiving_first? and document.archives.where("template_id IS NOT NULL").count.zero?) or
          (self.archiving_first_of_template? and document.archives.where(:template_id => self.id).count.zero?) or
          self.archiving.to_s =~ /^(last|all)(\_of\_template)?$/
        document.archive(data, format, options.merge(:template_id => self.id))
      end
    end
    return document
  end


  # Returns the root directory for the document templates's sources
  def self.sources_root
    Ekylibre.private_directory.join("reporting")
  end

  # Loads in DB all default document templates
  def self.load_defaults(options = {})
    locale = (options[:locale] || Entity.of_company.language || I18n.locale).to_s
    Ekylibre::Record::Base.transaction do
      manageds = self.where(:managed => true).pluck(:id)
      for nature in self.nature.values
        source = Rails.root.join("config", "locales", locale, "prints", "#{nature}.xml")
        if source.exist?
          File.open(source, "rb:UTF-8") do |f|
            unless template = self.where(:nature => nature, :managed => true).first
              template = self.new(:nature => nature, :managed => true, :active => true, :by_default => false, :archiving => "last")
            end
            manageds.delete(template.id)
            template.attributes = {:source => f, :language => locale}
            template.name ||= template.nature.text
            template.save!
          end
          logger.info "NOTICE: Load a default document template #{nature}"
        else
          logger.info "WARNING: Cannot load a default document template #{nature}: No file found at #{source}"
        end
      end
      self.destroy(manageds)
    end
    return true
  end


end
