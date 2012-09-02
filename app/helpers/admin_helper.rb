module AdminHelper

  def cta_req?
    @approve_sos || @suspend_user || @unflag_user || @unflag_photo || @activate_user || @delete_photo || @delete_user
  end

  def sortable(column, title = nil)
    title ||= column.titleize
    css_class = column == sort_column ? "current #{sort_direction}" : nil
    direction = column == sort_column && sort_direction == "asc" ? "desc" : "asc"
    link_to title, params.merge({:sort => column, :direction => direction}), {:class => css_class}
  end
end
