# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Export::Csv::People

  # Attributes of people we want to include
  class PeopleAddress < Export::Csv::Base

    self.model_class = ::Person
    self.row_class = PersonRow


    private

    def build_attribute_labels
      person_attribute_labels.merge(association_attributes)
    end

    def person_attribute_labels
      person_attributes.each_with_object({}) do |attr, hash|
        hash[attr] = attribute_label(attr)
      end
    end

    def person_attributes
      [:first_name, :last_name, :nickname, :company_name, :company, :email,
       :address, :zip_code, :town, :country, :gender, :birthday, :roles]
    end

    def association_attributes
      account_labels(people.map(&:phone_numbers).flatten.select(&:public?),
                     Accounts.phone_numbers)
    end

    def account_labels(collection, mapper)
      collection.map(&:label).uniq.each_with_object({}) do |label, obj|
        obj[mapper.key(label)] = mapper.human(label) if label.present?
      end
    end

    def people
      list
    end
  end
end
