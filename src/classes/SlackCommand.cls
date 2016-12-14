/**
 * helper class
 */
global abstract class SlackCommand {
    //CONSTANTS
    public static final String EPHEMERAL = 'ephemeral';
    public static final String IN_CHANNEL = 'in_channel';
    public static final String COMMAND_PARAM = 'command';
    public static final String TEXT_PARAM = 'text';
    public static final String USER_ID_PARAM = 'user_id';


    global class SlackCommandParams {
        /**
         * Class that stores params sent from slack
         */
        public String text;
        public String userId;
        public String userName;
        public String responseUrl;
        public String channelName;
        public String channelId;
        public String command;

        public SlackCommandParams(Map<String, String> params){
            text = params.get('text');
            userId = params.get(USER_ID_PARAM);
            userName = params.get('user_name');
            responseUrl = params.get('response_url');
            channelName = params.get('channel_name');
            channelId = params.get('channel_id');
            command = params.get(COMMAND_PARAM);
        }
    }

    //=== DTO ===
    global class SlackResponse{
        public SlackResponse(String text){
            this.response_type = EPHEMERAL; //default
            this.text = text;
        }
        public String response_type { get; set; }
        public String text { get; set; }
        public List<Attachment> attachments { get; set; }
    }

    public class Attachment{
        public Attachment(String text){
            this.text = text;
        }
        public String text { get; set; }
    }
}