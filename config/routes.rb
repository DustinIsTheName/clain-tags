Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html


  post 'get-survey' => 'survey#get_survey'
  get 'get-survey' => 'survey#get_survey_test'

end
