# -*- coding: utf-8 -*-
# = Informations
#
# == License
#
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier, Thibaud Merigon
# Copyright (C) 2012-2014 Brice Texier, David Joulin
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
# == Table: products
#
#  address_id            :integer
#  born_at               :datetime
#  category_id           :integer          not null
#  created_at            :datetime         not null
#  creator_id            :integer
#  dead_at               :datetime
#  default_storage_id    :integer
#  derivative_of         :string(120)
#  description           :text
#  financial_asset_id    :integer
#  id                    :integer          not null, primary key
#  identification_number :string(255)
#  initial_born_at       :datetime
#  initial_container_id  :integer
#  initial_dead_at       :datetime
#  initial_enjoyer_id    :integer
#  initial_father_id     :integer
#  initial_mother_id     :integer
#  initial_owner_id      :integer
#  initial_population    :decimal(19, 4)   default(0.0)
#  initial_shape         :spatial({:srid=>
#  lock_version          :integer          default(0), not null
#  name                  :string(255)      not null
#  nature_id             :integer          not null
#  number                :string(255)      not null
#  parent_id             :integer
#  picture_content_type  :string(255)
#  picture_file_name     :string(255)
#  picture_file_size     :integer
#  picture_updated_at    :datetime
#  tracking_id           :integer
#  type                  :string(255)
#  updated_at            :datetime         not null
#  updater_id            :integer
#  variant_id            :integer          not null
#  variety               :string(120)      not null
#  work_number           :string(255)
#

class Animal < Bioproduct
  enumerize :variety, in: Nomen::Varieties.all(:animal), predicates: {prefix: true}

  validates_presence_of :identification_number
  validates_uniqueness_of :identification_number

  scope :fathers, -> { indicate(sex: "male", reproductor: true).order(:name) }
  scope :mothers, -> { indicate(sex: "female", reproductor: true).order(:name) }

  def status
    if self.dead_at?
      return :stop
    elsif self.indicators_list.include? :healthy
      return (self.healthy ? :go : :caution)
    else
      return :go
    end
  end

  # # prepare method to call EDNOTIF to exchange with EDE via SOAP Webservice
  # # test with Fourniture de l’inventaire d’une exploitation
  # # need to active SAVON GEM when begin to work
  # def call_notification
  #   # 1. Contacter l'annuaire (WsAnnuaire) pour obtenir l’URL du webservice technique et du webservice métier à contacter
  #   profil = {Entreprise: 'FR17387001', Zone: '17'}
  #   client_ws_annuaire = Savon.client(wsdl: 'http://zoe.cmre.fr/wsannuaire/WsAnnuaire?wsdl')
  #   response = client_ws_annuaire.call(:tk_get_services, message: {Espece: 'B'})

  #   response = client_ws_annuaire.call(:tk_get_url, message: {ProfilDemandeur: profil})

  #   # 2. Appeler le webservice technique (WsGuichet) pour authentification et obtention jeton
  #   client_ws_guichet = Savon.client(wsdl: 'https://zoe.cmre.fr/wsguichet/WsGuichet?wsdl')
  #   response = client_ws_guichet.call(:tk_get_url)
  #   token = response.header

  #   # 3. Appeler le webservice métier muni du jeton

  #   client_ws_metier = Savon.client(wsdl: 'http://zoe.cmre.fr/wsIpBNotif/wsIpBNotif?wsdl')
  #   client.operations
  #   response = client_ws_metier.call(:ip_b_get_inventaire,
  #                                    message: { JetonAuthentification: token,
  #                                      Exploitation: "FR17387001",
  #                                      DateDebut: "2013-01-01",
  #                                      DateFin: "2013-06-01",
  #                                      StockBoucles: true
  #                                    })
  #   response.body
  # end

  def sex_text
    "nomenclatures.sexes.items.#{self.sex}".t
  end

end
