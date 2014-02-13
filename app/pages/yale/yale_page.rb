#encoding: utf-8
class YalePage
  include PageObject
  page_url 'www.yale.edu'

  table 'news', id: 'news'
  text_field 'search', name: 'q'
  button 'searchButton', id: 'edit-submit'
  
  def search_for kw
    self.search = kw
    self.search_element.send_keys :enter
    turn_to YaleSearchResultPage
  end
end
