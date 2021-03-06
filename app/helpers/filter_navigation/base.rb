# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module FilterNavigation
  class Base
    include Translatable

    attr_reader :template, :main_items, :dropdown, :active_label

    delegate :content_tag, :link_to, to: :template

    def initialize(template)
      @template = template
      @main_items = []
      @active_label = nil
      @dropdown = Dropdown.new(template)
    end


    def to_s
      content_tag(:div, class: 'toolbar-pills') do
        content_tag(:ul, class: 'nav nav-pills group-pills') do
          items = main_items
          if dropdown.items.present?
            items << content_tag(:li, class: "dropdown #{'active' if dropdown.active}") do
              template.in_button_group { dropdown.to_s }
            end
          end
          template.safe_join(items)
        end
      end
    end

    private

    def item(label, url)
      @main_items << content_tag(:li,
                                 link_to(label, url),
                                 class: ('active' if active_label == label))
    end

  end

  class Dropdown < Dropdown::Base

    attr_accessor :active

    def initialize(template)
      super(template, translate(:additional_views))
      @active = false
      @button_class = nil
    end
  end
end
