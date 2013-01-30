# encoding: utf-8
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009-2012 Brice Texier
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
# along with this program.  If not, see <http://www.gnu.org/licenses/>.
#

class BaseController < ApplicationController


  def notify(message, options={}, nature=:information, mode=:next)
    notistore = (mode==:now ? flash.now : flash)
    notistore[:notifications] = {} unless notistore[:notifications].is_a? Hash
    notistore[:notifications][nature] = [] unless notistore[:notifications][nature].is_a? Array
    notistore[:notifications][nature] << ::I18n.t("notifications."+message.to_s, options)
  end
  def notify_error(message, options={});   notify(message, options, :error); end
  def notify_warning(message, options={}); notify(message, options, :warning); end
  def notify_success(message, options={}); notify(message, options, :success); end
  def notify_now(message, options={});         notify(message, options, :information, :now); end
  def notify_error_now(message, options={});   notify(message, options, :error, :now); end
  def notify_warning_now(message, options={}); notify(message, options, :warning, :now); end
  def notify_success_now(message, options={}); notify(message, options, :success, :now); end

  def has_notifications?(nature=nil)
    return false unless flash[:notifications].is_a? Hash
    if nature.nil?
      for nature, messages in flash[:notifications]
        return true if messages.size > 0
      end
    elsif flash[:notifications][nature].is_a?(Array)
      return true if flash[:notifications][nature].size > 0
    end
    return false
  end

end
