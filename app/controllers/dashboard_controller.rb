# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

class DashboardController < ApplicationController

  skip_before_action :authenticate_person!, only: :index
  skip_authorization_check only: :index

  def index
    flash.keep
    if current_user
      redirect_to person_home_path(current_user)
    else
      redirect_to new_person_session_path
    end
  end
end
