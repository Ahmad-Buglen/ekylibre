# encoding: utf-8
# == License
# Ekylibre - Simple ERP
# Copyright (C) 2009-2013 Brice Texier
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

class Authentication::SessionsController < ::Devise::SessionsController

  # # Permits to renew the session if expired
  # def renew
  #   if request.post?
  #     if user = User.authenticate(params[:name], params[:password])
  #       session[:last_query] = Time.now.to_i
  #       head :ok, :x_return_code: "granted"
  #       return
  #     else
  #       @no_authenticated = true
  #       response.headers["X-Return-Code"] = "denied"
  #       notify_error_now(:no_authenticated)
  #     end
  #   end
  #   render :renew, layout: false
  # end

end
