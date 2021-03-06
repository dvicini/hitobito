# encoding: utf-8

#  Copyright (c) 2012-2014, Jungwacht Blauring Schweiz, Pfadibewegung Schweiz.
#  This file is part of hitobito and licensed under the Affero General Public
#  License version 3 or later. See the COPYING file at the top-level directory
#  or at https://github.com/hitobito/hitobito.


module Export::Csv
  # The base class for all the different csv export files.
  class Base

    class_attribute :model_class, :row_class

    attr_reader :list

    class << self
      def export(*args)
        Export::Csv::Generator.new(new(*args)).csv
      end
    end

    def initialize(list)
      @list = list
    end

    def to_csv(generator)
      generator << labels
      list.each do |entry|
        generator << values(entry)
      end
    end

    # The list of all attributes exported to the csv.
    # overridde either this or #attribute_labels
    def attributes
      attribute_labels.keys
    end

    # A hash of all attributes mapped to their labels exported to the csv.
    # overridde either this or #attributes
    def attribute_labels
      @attribute_labels ||= build_attribute_labels
    end

    # List of all lables.
    def labels
      attribute_labels.values
    end

    private

    def build_attribute_labels
      attributes.each_with_object({}) do |attr, labels|
        labels[attr] = attribute_label(attr)
      end
    end

    def attribute_label(attr)
      human_attribute(attr)
    end

    def human_attribute(attr)
      model_class.human_attribute_name(attr)
    end

    def values(entry)
      row = row_class.new(entry)
      attributes.collect { |attr| normalize(row.fetch(attr)) }
    end

    def normalize(value)
      if value == true
        I18n.t('global.yes')
      elsif value == false
        I18n.t('global.no')
      else
        value
      end
    end

    # Decorator for a row entry.
    # Attribute values may be accessed with fetch(attr).
    # If a method named #attr is defined on the decorator class, return its value.
    # Otherwise, the attr is delegated to the entry.
    class Row

      # regexp for attribute names which are handled dynamically.
      class_attribute :dynamic_attributes
      self.dynamic_attributes = {}

      attr_reader :entry

      def initialize(entry)
        @entry = entry
      end

      def fetch(attr)
        if dynamic_attribute?(attr.to_s)
          handle_dynamic_attribute(attr)
        elsif respond_to?(attr, true)
          send(attr)
        else
          entry.send(attr)
        end
      end

      private

      def dynamic_attribute?(attr)
        dynamic_attributes.any? { |regexp, _| attr =~ regexp }
      end

      def handle_dynamic_attribute(attr)
        dynamic_attributes.each do |regexp, handler|
          if attr.to_s =~ regexp
            return send(handler, attr)
          end
        end
      end

    end

    self.row_class = Row
  end

end
