# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Subscriber
  class PersonController < BaseController

    skip_authorize_resource # must be in leaf class

    before_render_form :replace_validation_errors

    private

    def subscriber
      Person.find(subscriber_id)
    end

    def build_entry
      find_excluded_subscription || model_scope.new
    end

    def find_excluded_subscription
      if subscriber_id
        mailing_list.subscriptions.where(subscriber_id: subscriber_id,
                                         subscriber_type: Person.sti_name, excluded: true).first
      end
    end

    def model_label
      Person.model_name.human
    end
  end
end
