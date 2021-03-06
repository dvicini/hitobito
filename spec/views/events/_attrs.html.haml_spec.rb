# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'

describe 'events/_attrs.html.haml' do

  let(:top_leader) { people(:top_leader) }

  before do
    assign(:event, event)
    assign(:group, event.groups.first)
    view.stub(action_name: 'events', current_user: top_leader, entry: event)
    controller.stub(current_user: top_leader)
    render
  end

  let(:dom) { Capybara::Node::Simple.new(rendered) }

  subject { dom }

  context 'course' do
    let(:event) { EventDecorator.decorate(events(:top_course)) }
    it 'lists preconditions' do
      should have_content 'Qualifikationen'
      should have_content 'Group Lead'
    end
  end

  context 'event' do
    let(:event) { EventDecorator.decorate(events(:top_event)) }
    it 'lists preconditions' do
      should_not have_content 'Qualifikationen'
    end
  end


  context 'event dates' do
    let(:event) { EventDecorator.decorate(event_with_date) }
    let(:event_with_date) { Fabricate(:event_date, event: events(:top_event), label: 'Vorweekend', location: 'Im Wald').event }
    it 'joins event date label and location' do
      should have_content 'Vorweekend, Im Wald'
    end
  end

end
