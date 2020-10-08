var conn = new Mongo();
var db = conn.getDB("im_db");
var n_users = 1*Math.pow(10, 4);
var n_conversations = 1*Math.pow(10, 3);
var conversation_map = {};
var password = "$2b$12$vd7V3b6YJgK/AGk9.EimM.V7k8B3HWSAsBiY0ou3hNWf3cU4sfKkO"; // "test" 
var user_bulk = db.user.initializeUnorderedBulkOp();
var conversation_bulk = db.conversation.initializeUnorderedBulkOp();
var update_user_bulk = db.user.initializeUnorderedBulkOp();
var update_conversation_bulk = db.conversation.initializeUnorderedBulkOp();


for(i=1; i<=n_users; i++) {
    user = {
        username: `user${i}`,
        password: password,
        conversations: [] 
    };
    user_bulk.insert(user);
}
user_bulk.execute()
db.user.createIndex({username: 1})

for(i=1; i<=n_conversations; i++) {
    conversation = {
        conversation_id: `${new Date().getTime()}${getRandomInt(0, 1000)}`,
        name: `conv${i}`,
        created_at: new Date(),
        participants: []
    };

    conversation_bulk.insert(conversation);
    conversation_map[conversation.name] = conversation.conversation_id;
}
conversation_bulk.execute();
db.conversation.createIndex({conversation_id:1})

for(let i=1; i<=n_users; i++) {
    let n_user_conversations = getRandomInt(1, 3);
    let username = `user${i}`;

    let used_conversations = []
    for(let j=0; j<n_user_conversations; j++) {
        // generate ID 
        let conv_num = getRandomInt(1, n_conversations);
        while (used_conversations.includes(conv_num)) {
            conv_num = getRandomInt(1, n_conversations);
        }

        let conversation_name = `conv${conv_num}`;
        let conversation_id = conversation_map[conversation_name];
        let participant = {
            username: username,
            last_msg_seen: "0",
            unread_msg_count: "0"
        };

        update_user_bulk
            .find({username: username})
            .update({"$push": {conversations: conversation_id}});
        
        update_conversation_bulk
            .find({conversation_id: conversation_id})
            .update({"$push": {participants: participant}});
    }
}
update_user_bulk.execute()
update_conversation_bulk.execute()

function getRandomInt(min, max) {
    min = Math.ceil(min);
    max = Math.floor(max);
    return Math.floor(Math.random() * (max - min) + min);
}
