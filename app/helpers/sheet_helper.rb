# encoding: utf-8

#  Copyright (c) 2012-2013, Jungwacht Blauring Schweiz. This file is part of
#  hitobito and licensed under the Affero General Public License version 3
#  or later. See the COPYING file at the top-level directory or at
#  https://github.com/hitobito/hitobito.

# Implement a stack based navigation system.
#
# We always place a sheet for the current page on the stack, the previous
# sheet should return the user to where he came from
#
module SheetHelper

  # Get or set the title of the current sheet
  def title(string = nil)
    if string
      sheet.title = string
    else
      sheet.title
    end
  end

  def render_sheets(&block)
    sheet.root.render(&block)
  end

  def sheet
    @sheet ||= sheet_for_controller
  end

  private

  def sheet_for_controller
    sheet_class_name = controller.class.name.gsub(/Controller/, '').singularize
    sheet_class = "Sheet::#{sheet_class_name}".constantize rescue Sheet::Base
    if action_name == 'index' && sheet_class.parent_sheet
      sheet_class = sheet_class.parent_sheet
    end
    sheet_class.new(self)
  end

end
