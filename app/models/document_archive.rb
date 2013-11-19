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
# == Table: document_archives
#
#  archived_at       :datetime         not null
#  created_at        :datetime         not null
#  creator_id        :integer
#  document_id       :integer          not null
#  file_content_text :text
#  file_content_type :string(255)
#  file_file_name    :string(255)
#  file_file_size    :integer
#  file_fingerprint  :string(255)
#  file_pages_count  :integer
#  file_updated_at   :datetime
#  id                :integer          not null, primary key
#  lock_version      :integer          default(0), not null
#  template_id       :integer
#  updated_at        :datetime         not null
#  updater_id        :integer
#
class DocumentArchive < Ekylibre::Record::Base
  # Returns the private directory for the archives
  def self.private_directory
    Ekylibre.private_directory.join('document-archives')
  end

  belongs_to :document, :counter_cache => :archives_count, inverse_of: :archives
  belongs_to :template, class_name: "DocumentTemplate"
  has_attached_file :file, {
    :path => self.private_directory.join(':id_partition', ':style.:extension').to_s,
    :styles => {
      default: {:clean => true, :format => :pdf, :processors => [:reader, :counter, :freezer]},
      :thumbnail => {:processors => [:sketcher], :format => :jpg}
    }
  }
  #[VALIDATORS[ Do not edit these lines directly. Use `rake clean:validations`.
  validates_numericality_of :file_file_size, allow_nil: true, only_integer: true
  validates_length_of :file_content_type, :file_file_name, :file_fingerprint, allow_nil: true, maximum: 255
  validates_presence_of :archived_at, :document
  #]VALIDATORS]
  validates_presence_of :archived_at
  validates_attachment_presence :file

  before_validation(on: :create) do
    self.archived_at ||= Time.now
  end

  delegate :name, to: :template, prefix: true

  # Returns data of file
  def data
    path = self.file.path
    file_data = nil
    if path.exist?
      File.open(path, "rb") do |file|
        file_data = file.read
      end
    else
      raise StandardError.new("Archive (#{path}) does not exists!")
    end
    return file_data
  end

end
