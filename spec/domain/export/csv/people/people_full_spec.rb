# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe Export::Csv::People::PeopleFull do

  let(:person) { people(:top_leader) }
  let(:list) { [person] }
  let(:people_list) { Export::Csv::People::PeopleFull.new(list) }
  subject { people_list }

  its([:roles]) { should eq 'Rollen' }
  its(:attributes) do should eq [:first_name, :last_name, :company_name, :nickname, :company, :email, :address,
                                 :zip_code, :town, :country, :gender, :birthday, :additional_information] end

  its([:social_account_website]) { should be_blank }

  its([:company]) { should eq 'Firma' }
  its([:company_name]) { should eq 'Firmenname' }

  context 'social accounts' do
    before { person.social_accounts << SocialAccount.new(label: 'Webseite', name: 'foo.bar') }
    its([:social_account_webseite]) { should eq 'Social Media Adresse Webseite' }
  end
end