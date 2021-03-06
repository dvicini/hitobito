# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

module Sheet
  class Base
    include Translatable

    class_attribute :parent_sheet, :has_tabs
    self.has_tabs = false

    attr_accessor :title
    attr_reader :view, :child, :entry
    attr_writer :parent_sheet

    delegate :content_tag, :link_to, :safe_join, :capture, :can?, :request, to: :view

    class << self
      def with_parent(view, parent, parent_entry = nil)
        sheet = new(view)
        sheet.create_parent(parent, parent_entry)
        sheet
      end
    end

    def initialize(view, child = nil, entry = nil)
      @view = view
      @child = child
      @entry = entry || find_entry
      @title = @entry.to_s if @entry
    end

    def render(&block)
      content_tag(:div, class: "sheet #{css_class}") do
        current? ? render_as_current(&block) : render_as_parent(&block)
      end
    end

    def render_main_tabs
      unless %w(new edit create update).include?(view.action_name)
        render_tabs
      end
    end

    def render_tabs
      if has_tabs
        view.tab_bar(current_nav_path) do |bar|
          view.render("#{model_name.pluralize}/tabs", model_name.to_sym => entry, bar: bar)
        end
      end
    end

    def root
      if parent_sheet
        parent_sheet.root
      else
        self
      end
    end

    def parent_sheet
      @parent_sheet ||= self.class.parent_sheet ? create_parent(self.class.parent_sheet) : nil
    end

    def create_parent(clazz, entry = nil)
      @parent_sheet = clazz.new(view, self, entry).tap do |p|
        p.title = p.entry.to_s
      end
    end

    protected

    def current_nav_path
      current? ? request.path : child.current_parent_nav_path
    end

    def current_parent_nav_path
      request.path
    end

    private

    def render_as_current(&block)
      content_tag(:div, class: 'container-shadow') do
        content_tag(:div, id: 'content') do
          render_breadcrumbs +
          capture(&block)
        end
      end
    end

    def render_as_parent(&block)
      render_breadcrumbs +
      render_parent_title +
      render_tabs +
      child.render(&block)
    end

    # title in parent sheet
    def render_parent_title
      if link_url
        link_to(title, link_url, class: 'level active')
      else
        content_tag(:div, title, class: 'level active')
      end
    end

    # URL for the title link
    def link_url
      nil
    end

    def render_breadcrumbs
      ''.html_safe
    end

    def css_class
      current? ? 'current' : 'parent'
    end

    def current?
      child.blank?
    end

    def find_entry
      view.instance_variable_get(:"@#{model_name}")
    end

    def model_name
      self.class.name.demodulize.underscore
    end
  end
end
