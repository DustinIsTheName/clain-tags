class SurveyController < ApplicationController

  skip_before_filter :verify_authenticity_token

  def get_survey_test
    head :ok
  end

  def get_survey
    puts Colorize.magenta(params)
    puts Colorize.magenta(request.raw_post)

    request_raw_post = JSON.parse(request.raw_post)

    survey_id = request_raw_post["resources"]["survey_id"]
    respondent_id = request_raw_post["resources"]["respondent_id"]

    survey_details = survey_request("https://api.surveymonkey.com/v3/surveys/#{survey_id}/details")

    questions = []
    for p in survey_details["pages"]
      questions += p["questions"]
    end

    puts Colorize.cyan(survey_id)
    puts Colorize.cyan(respondent_id)

    survey_response = survey_request("https://api.surveymonkey.com/v3/surveys/#{survey_id}/responses/#{respondent_id}/details")

    question_results = []
    for p in survey_response["pages"]
      question_results += p["questions"]
    end




    tags = {}

    tags["email"] = nil
    tags["height"] = []
    tags["dress"] = []
    tags["shirt_blouse"] = []
    tags["skirt"] = []
    tags["pant"] = []
    tags["shoe"] = []
    tags["arms"] = []
    tags["shoulders"] = []
    tags["torso"] = []
    tags["hips"] = []
    tags["legs"] = []
    tags["curvy"] = []
    tags["top_fit"] = []
    tags["pant_rise"] = []
    tags["pant_length"] = []
    tags["arms_assets"] = []
    tags["shoulders_assets"] = []
    tags["midsection_assets"] = []
    tags["rear_assets"] = []
    tags["legs_assets"] = []
    tags["work_business_casual"] = []
    tags["cocktail_wedding"] = []
    tags["laidback_casual"] = []
    tags["date_night_night_out"] = []
    tags["style_preference"] = []
    tags["shop"] = []
    tags["jewelry"] = []
    tags["jewelry_metal"] = []
    tags["colors"] = []
    tags["prints"] = []
    tags["fabrics"] = []
    tags["birthday"] = []
    tags["occupation"] = []
    tags["facebook"] = []
    tags["instagram"] = []
    tags["pinterest"] = []
    tags["other"] = []
    tags["info"] = []

    for result in question_results
      question = questions.select{|q| q["id"] == result["id"]}.first

      if question
        question_heading = question["headings"].first["heading"].gsub(/\A\p{Space}*|\p{Space}*\z/, '')

        case question_heading
        when "Email"
          tags["email"] = result["answers"].first["text"]
        when "How tall are you?"
          tags["height"] << result["answers"].first["text"]
        when "Dress"
          tags["dress"] = parse_answers(question, result)
        when "Shirt & Blouse"
          tags["shirt_blouse"] = parse_answers(question, result)
        when "Skirt"
          tags["skirt"] = parse_answers(question, result)
        when "Pants"
          tags["pant"] = parse_answers(question, result)
        when "Shoe"
          tags["shoe"] = parse_answers(question, result)
        when "Arms:"
          tags["arms"] = parse_answers(question, result)
        when "Shoulders:"
          tags["shoulders"] = parse_answers(question, result)
        when "Torso:"
          tags["torso"] = parse_answers(question, result)
        when "Hips:"
          tags["hips"] = parse_answers(question, result)
        when "Legs:"
          tags["legs"] = parse_answers(question, result)
        when "Would you consider your bottom half curvy?"
          tags["curvy"] = parse_answers(question, result)
        when "What fit do you like on top?"
          tags["top_fit"] = parse_answers(question, result)
        when "What rise do you prefer?"
          tags["pant_rise"] = parse_answers(question, result)
        when "What length do you like?"
          tags["pant_length"] = parse_answers(question, result)
        when "My Arms:"
          tags["arms_assets"] = parse_answers(question, result)
        when "My Shoulders:"
          tags["shoulders_assets"] = parse_answers(question, result)
        when "My Midsection:"
          tags["midsection_assets"] = parse_answers(question, result)
        when "My Rear:"
          tags["rear_assets"] = parse_answers(question, result)
        when "My Legs:"
          tags["legs_assets"] = parse_answers(question, result)
        when "Work/ Business Casual:"
          tags["work_business_casual"] = parse_answers(question, result)
        when "Cocktail/Wedding/Event:"
          tags["cocktail_wedding"] = parse_answers(question, result)
        when "Laid back/Casual:"
          tags["laidback_casual"] = parse_answers(question, result)
        when "Date night/Night out:"
          tags["date_night_night_out"] = parse_answers(question, result)
        when "Are you more of a pants/jeans/skirts and top girl or a dresses girl?"
          tags["style_preference"] = parse_answers(question, result)
        when "Where do you shop?"
          tags["shop"] << result["answers"].first["text"]
        when "What type of jewelry do you enjoy?"
          tags["jewelry"] = parse_answers(question, result)
        when "Gold or silver?"
          tags["jewelry_metal"] = parse_answers(question, result)
        when "What colors do you like?"
          tags["colors"] = parse_answers(question, result)
        when "What prints do you like?"
          tags["prints"] = parse_answers(question, result)
        when "What fabrics do you like?"
          tags["fabrics"] = parse_answers(question, result)
        when "When is your birthday?"
          tags["birthday"] << result["answers"].first["text"]
        when "What is your primary occupation?"
          tags["occupation"] << result["answers"].first["text"]
        when "Facebook"
          tags["facebook"] << result["answers"].first["text"]
        when "Instagram"
          tags["instagram"] << result["answers"].first["text"]
        when "Pinterest"
          tags["pinterest"] << result["answers"].first["text"]
        when "Other"
          tags["other"] << result["answers"].first["text"]
        when "Please use the box below to tell us anything else you would like us to know about you, anything at all including specific likes and dislikes."
          tags["info"] << result["answers"].first["text"]
        end
      end
    end

    customer = ShopifyAPI::Customer.search(query: "email:#{tags["email"]}").first

    for tag_key in tags.keys

      if tags[tag_key].class.to_s == "Array"
        tag_key_formatted = tag_key.split('_').map{|x| x.capitalize}.join('-')

        for t in tags[tag_key]
          customer.tags = customer.tags.add_tag("#{tag_key_formatted}: #{t}")
        end
      end
    end

    customer.save


    head :ok
  end

  private

    def parse_answers(question, result)

      puts question

      answers = []

      for answer in result["answers"]
        choice = question["answers"]["choices"].select{|c|c["id"] === answer["choice_id"]}.first
        if choice
          answers << choice["text"]
        end
      end

      answers
    end

    def survey_request(url)

      uri = URI.parse(url)
      request = Net::HTTP::Get.new(uri)
      request["Authorization"] = "bearer #{ENV["SURVEYMONKEY_API_KEY"]}"
      request["Content-Type"] = ""

      req_options = {
        use_ssl: uri.scheme == "https",
      }

      response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
        http.request(request)
      end

      JSON.parse response.read_body

    end

end