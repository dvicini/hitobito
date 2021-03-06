# encoding: utf-8
# == Schema Information
#
# Table name: event_kinds
#
#  id          :integer          not null, primary key
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  deleted_at  :datetime
#  minimum_age :integer
#


#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.
Fabricator(:event_kind, class_name: 'Event::Kind') do
  label { Faker::Company.bs }
end
