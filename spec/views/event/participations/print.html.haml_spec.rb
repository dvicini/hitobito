# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

require 'spec_helper'
describe 'event/participations/print.html.haml' do
  let(:top_leader) { people(:top_leader) }
  let(:bottom_member) { people(:bottom_member) }

  let(:event) { Fabricate(:event, contact: top_leader) }
  let(:application) { Fabricate(:event_application, priority_1: event) }
  let(:participation) { Fabricate(:event_participation, application: application, person: bottom_member, event: event) }

  before do
    assign(:application, Event::ApplicationDecorator.decorate(application))
    assign(:event, EventDecorator.decorate(participation.event))
    view.stub(path_args: participation.event)
    view.stub(entry: Event::ParticipationDecorator.decorate(participation))
    controller.stub(current_user: bottom_member)
  end

  context 'html' do
    subject { render; Capybara::Node::Simple.new(rendered) }
    it 'has contact details for person  and application contact ' do
      should have_content top_leader.email
      should have_content bottom_member.email
    end
  end


  it 'has event location, motto and description, renderd with simple_format' do
    event.motto = 'Welcome On Board'
    event.description = "foo\nbar"
    event.location = "blub\nbla"
    render
    rendered.should =~ %r{Welcome On Board}
    rendered.should =~ %r{<br />bar}
    rendered.should =~ %r{<br />bla}
  end

end
