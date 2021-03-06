# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# == Schema Information
#
# Table name: events
#
#  id                     :integer          not null, primary key
#  type                   :string(255)
#  name                   :string(255)      not null
#  number                 :string(255)
#  motto                  :string(255)
#  cost                   :string(255)
#  maximum_participants   :integer
#  contact_id             :integer
#  description            :text
#  location               :text
#  application_opening_at :date
#  application_closing_at :date
#  application_conditions :text
#  kind_id                :integer
#  state                  :string(60)
#  priorization           :boolean          default(FALSE), not null
#  requires_approval      :boolean          default(FALSE), not null
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#  participant_count      :integer          default(0)
#  application_contact_id :integer
#  external_applications  :boolean          default(FALSE)
#

require 'spec_helper'

describe Event do

  let(:event) { events(:top_course) }

  context '#participations' do

    let(:event) { events(:top_event) }

    subject do
      Fabricate(Event::Role::Leader.name.to_sym, participation:  Fabricate(:event_participation, event: event))
      Fabricate(Event::Role::Participant.name.to_sym, participation:  Fabricate(:event_participation, event: event))
      p = Fabricate(:event_participation, event: event)
      Fabricate(Event::Role::Participant.name.to_sym, participation: p)
      Fabricate(Event::Role::Participant.name.to_sym, participation: p, label: 'Irgendwas')
      event.reload
    end
    its(:participant_count) { should == 2 }
  end


  context '#application_possible?' do

    context 'without opening and closing dates' do
      it 'is open without maximum participant' do
        should be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        should_not be_application_possible
      end

      it 'is open when maximum participants is not yet reached' do
        subject.maximum_participants = 20
        subject.participant_count = 19
        should be_application_possible
      end
    end

    context 'with closing date in the future' do
      before { subject.application_closing_at = Date.today + 1 }

       it 'is open without maximum participant' do
        should be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        should_not be_application_possible
      end

    end

    context 'with closing date today' do
      before { subject.application_closing_at = Date.today }

      it 'is open without maximum participant' do
        should be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        should_not be_application_possible
      end
    end

    context 'with closing date in the past' do
      before { subject.application_closing_at = Date.today - 1 }

      it 'is closed without maximum participant' do
        should_not be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        should_not be_application_possible
      end
    end


    context 'with opening date in the past' do
      before { subject.application_opening_at = Date.today - 1 }

      it 'is open without maximum participant' do
        should be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        should_not be_application_possible
      end
    end

    context 'with opening date today' do
      before { subject.application_opening_at = Date.today }

      it 'is open without maximum participant' do
        should be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        should_not be_application_possible
      end
    end

    context 'with opening date in the future' do
      before { subject.application_opening_at = Date.today + 1 }

      it 'is closed without maximum participant' do
        should_not be_application_possible
      end
    end

    context 'with opening and closing dates' do
      before do
        subject.application_opening_at = Date.today - 2
        subject.application_closing_at = Date.today + 2
      end

      it 'is open' do
        should be_application_possible
      end

      it 'is closed when maximum participants is reached' do
        subject.maximum_participants = 20
        subject.participant_count = 20
        should_not be_application_possible
      end

      it 'is open when maximum participants is not yet reached' do
        subject.maximum_participants = 20
        subject.participant_count = 19
        should be_application_possible
      end
    end

    context 'with opening and closing dates in the future' do
      before do
        subject.application_opening_at = Date.today + 1
        subject.application_closing_at = Date.today + 2
      end

      it 'is closed' do
        should_not be_application_possible
      end
    end

    context 'with opening and closing dates in the past' do
      before do
        subject.application_opening_at = Date.today - 2
        subject.application_closing_at = Date.today - 1
      end

      it 'is closed' do
        should_not be_application_possible
      end
    end
  end

  context 'finders' do

    context '.since' do
      let(:since) { Time.zone.parse('2013-01-10 14:24:21') }

      let!(:yesterday) { event_with_date(since - 1.day) }
      let!(:tomorrow) { event_with_date(since + 1.day) }

      subject { Event.since(since) }

      it { should include tomorrow }
      it { should_not include yesterday }

      def event_with_date(start_at)
        event = Fabricate(:event)
        event.dates.first.update_attribute(:start_at, start_at)
        event
      end
    end

    context '.in_year' do
      context 'one date' do
        before { set_start_finish(event, '2000-01-02') }

        it 'uses dates create_at to determine if event matches' do
          Event.in_year(2000).size.should eq 1
          Event.in_year(2001).should_not be_present
          Event.in_year(2000).first.should eq event
          Event.in_year('2000').first.should eq event
        end

      end

      context 'starting at last day of year and another date in the following year' do
        before { set_start_finish(event, '2010-12-31 17:00') }
        before { set_start_finish(event, '2011-01-20') }

        it 'finds event in old year' do
          Event.in_year(2010).should == [event]
        end

        it 'finds event in following year' do
          Event.in_year(2011).should == [event]
        end

        it 'does not find event in past year' do
          Event.in_year(2009).should be_blank
        end
      end
    end

    context '.upcoming' do
      subject { Event.upcoming }
      it 'does not find past events' do
        set_start_finish(event, '2010-12-31 17:00')
        should_not be_present
      end

      it 'does find upcoming event' do
        event.dates.create(start_at: 2.days.from_now, finish_at: 5.days.from_now)
        should eq [event]
      end

      it 'does find running event' do
        event.dates.create(start_at: 2.days.ago, finish_at: Time.zone.now)
        should eq [event]
      end

      it 'does find event ending at 5 to 12' do
        event.dates.create(start_at: 2.days.ago, finish_at: Time.zone.now.midnight + 23.hours + 55.minutes)
        should eq [event]
      end

      it 'does not find event ending at 5 past 12' do
        event.dates.create(start_at: 2.days.ago, finish_at: Time.zone.now.midnight - 5.minutes)
        should be_blank
      end

      it 'does find event with only start date' do
        event.dates.create(start_at: 1.day.from_now)
        should eq [event]
      end

      it 'does find event with only start date' do
        event.dates.create(start_at: Time.zone.now.midnight + 5.minutes)
        should eq [event]
      end
    end
  end

  context 'validations' do
    subject { event }

    it 'is not valid without event_dates' do
      event.dates.clear
      event.valid?.should be_false
      event.errors[:dates].should be_present
    end

    it 'is valid with application closing after opening' do
      subject.application_opening_at = Date.today - 5
      subject.application_closing_at = Date.today + 5
      subject.valid?

      should be_valid
    end

    it 'is not valid with application closing before opening' do
      subject.application_opening_at = Date.today - 5
      subject.application_closing_at = Date.today - 6

      should_not be_valid
    end

    it 'is valid with application closing and without opening' do
      subject.application_closing_at = Date.today - 6

      should be_valid
    end

    it 'is valid with application opening and without closing' do
      subject.application_opening_at = Date.today - 6

      should be_valid
    end

    it 'requires groups' do
      subject.group_ids = []

      should have(1).error_on(:group_ids)
    end
  end

  context '#init_questions' do
    it 'adds 3 default questions for courses' do
      e = Event::Course.new
      e.init_questions
      e.questions.should have(3).items
    end

    it 'does nothing for regular events' do
      e = Event.new
      e.init_questions
      e.questions.should be_blank
    end
  end

  context 'event_dates' do
    let(:e) { event }

    it "should update event_date's start_at time" do
      d = Time.zone.local(2012, 12, 12).to_date
      e.dates.create(label: 'foo', start_at: d, finish_at: d)
      ed = e.dates.first
      e.update_attributes(dates_attributes: { '0' => { start_at_date: d, start_at_hour: 18, start_at_min: 10, id: ed.id } })
      e.dates.first.start_at.should == Time.zone.local(2012, 12, 12, 18, 10)
    end

    it "should update event_date's finish_at date" do
      d1 = Time.zone.local(2012, 12, 12).to_date
      d2 = Time.zone.local(2012, 12, 13).to_date
      e.dates.create(label: 'foo', start_at: d1, finish_at: d1)
      ed = e.dates.first
      e.update_attributes(dates_attributes: { '0' => { finish_at_date: d2, id: ed.id } })
      e.dates.first.finish_at.should == Time.zone.local(2012, 12, 13, 00, 00)
    end

  end

  context 'participation role labels' do

    let(:event) { events(:top_event) }
    let(:participation) { Fabricate(:event_participation, event: event) }

    it 'should have 2 different labels' do
      Fabricate(Event::Role::Participant.name.to_sym, participation: participation, label: 'Foolabel')
      Fabricate(Event::Role::Participant.name.to_sym, participation: participation, label: 'Foolabel')
      Fabricate(Event::Role::Participant.name.to_sym, participation: participation, label: 'Just label')
      event.reload

      event.participation_role_labels.count.should eq 2
    end

    it 'should have no labels' do
      Fabricate(Event::Role::Participant.name.to_sym, participation: Fabricate(:event_participation, event: event))
      Fabricate(Event::Role::Participant.name.to_sym, participation: participation)
      event.reload

      event.participation_role_labels.count.should eq 0
    end

  end

  context 'destroyed associations' do
    let(:event) { events(:top_course) }

    it 'keeps destroyed kind' do
      event.kind.destroy
      event.reload

      event.kind.should be_present
    end

    context 'groups' do
      let(:group_one) { groups(:bottom_group_one_one) }
      let(:group_two) { groups(:bottom_group_one_two) }
      let(:event) { Fabricate(:event, groups: [group_one, group_two]) }

      it 'keeps destroyed groups' do
        event.groups.should have(2).items

        group_two.destroy
        group_two.should be_deleted
        event.reload

        event.groups.should have(2).items
      end
    end
  end


  def set_start_finish(event, start_at)
    start_at = Time.zone.parse(start_at)
    event.dates.create!(start_at: start_at, finish_at: start_at + 5.days)
  end

end
