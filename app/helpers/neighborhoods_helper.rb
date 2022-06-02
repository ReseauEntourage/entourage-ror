module NeighborhoodsHelper
  def neighborhood_status neighborhood
    type_to_class = {
      "active" => "label-info",
      "deleted" => "label-warning"
    }
    content_tag :span, neighborhood.status, class: "label #{type_to_class[neighborhood.status]}"
  end
end
