require 'twitter'
require 'yaml'



def authorize
  auth_keys=YAML.load_file("oauth_keys.yml")
  Twitter.configure do |config|
	  config.consumer_key=auth_keys["consumer_key"]
	  config.consumer_secret=auth_keys["consumer_secret"]
	  config.oauth_token=auth_keys["oauth_token"]
	  config.oauth_token_secret=auth_keys["oauth_token_secret"]
  end

end

def reply_mentions
  idstore=YAML.load_file("idstore.yml")
  last_mention=idstore["last_mention"]
  mentions=Twitter.mentions(:include_entities=>true,:since_id=>last_mention)
  responses=YAML.load_file("responses.yml")


  if mentions.length!=0

    mentions.each do |mention|
      reply=responses["thechelseabot"].sample
      Twitter.update("@#{mention.from_user} #{reply}",:in_reply_to_status_id=>mention.id)
      puts "Replied to: #{mention.from_user} (#{mention.id}) => #{reply}\n____________________________________________"
    end

    idstore["last_mention"]=mentions.last.id
  end
  File.open("idstore.yml","w") { |file| YAML.dump(idstore,file) }
end

def respond_to_tweets
  idstore=YAML.load_file("idstore.yml")
  last_search=idstore["last_search"]
  temp_last_search=0
  responses=YAML.load_file("responses.yml")


  responses.keys.each do |tag|

    Twitter.search("#chelsea AND #{tag}",:result_type=>"recent",:since_id=>last_search,:rpp=>10).results.map do |status|
      begin
        reply=responses[tag].sample
        Twitter.update("@#{status.from_user} #{reply}",:in_reply_to_status_id=>status.id)
        puts "Replied to: #{status.from_user} (#{status.id}) => #{reply}\n____________________________________________"
        temp_last_search=status.id
      rescue
        puts "Skipping.. Error Encountered"
      end
    end
  end
  if temp_last_search!=0
    idstore["last_search"]=temp_last_search
    File.open("idstore.yml","w") { |file| YAML.dump(idstore,file) }
  end
end

def follow_my_followers
  puts Twitter.follower_ids.attrs[:ids]
  followed=Twitter.friendship_create(Twitter.follower_ids.attrs[:ids])
  puts "\n\nNewly Followed ====================\n"
  if followed.length!=0
    followed.each do |user|
      puts "\n#{user.name}"
    end
  end
end

authorize
reply_mentions
respond_to_tweets
