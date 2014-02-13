#encoding: utf-8
class YaleSearchResultPage
	include PageObject
    div 'results', id: 'searchResults'
    
    def term_found? kw
      results_element.text.include?(kw)
    end
end
