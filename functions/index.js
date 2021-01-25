const functions = require('firebase-functions');

// The Firebase Admin SDK to access Firestore.
const admin = require('firebase-admin');
const { user } = require('firebase-functions/lib/providers/auth');
admin.initializeApp();

// // Create and Deploy Your First Cloud Functions
// // https://firebase.google.com/docs/functions/write-firebase-functions
//
// exports.helloWorld = functions.https.onRequest((request, response) => {
//   functions.logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });

exports.onUserUpdate = functions.firestore
    .document('users/{userId}')
    .onWrite(async (change, context) => {
        const userId = context.params.userId;

        // if followers list has been changed
        if (change.after.data()['followers'].length !== change.before.data()['followers'].length) {
            handleFollowerUpdate(userId, change);
        }
    })

async function handleFollowerUpdate(userId, change) {
    if (change.after.data()['followers'].length > change.before.data()['followers'].length) {
        let followersBefore = new Set(change.before.get('followers'));
        let followersAfter = change.after.get('followers');
        
        // get the new followerId
        const followerId = followersAfter.filter(id => !followersBefore.has(id))[0];
        console.log('added follower id:', followerId)

        // create followed user's posts ref
        const followedUserPostsRef = admin
            .firestore()
            .collection('posts')
            .doc(userId)
            .collection('usersPosts');

        // create following user's timeline ref
        const timelinePostsRef = admin
            .firestore()
            .collection('timeline')
            .doc(followerId)
            .collection('timelinePosts');

        // get followed user's posts
        const querySnapshot = await followedUserPostsRef.get();

        // add each user's post to following user's timeline
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                const postId = doc.id;
                const postData = doc.data();
                
                timelinePostsRef.doc(postId).set(postData);
            }
        });
    } else { //this condition is when a follower is deleted
        let followersBefore = change.before.get('followers');
        let followersAfter = new Set(change.after.get('followers'));
        
        // get the deleted followerId
        const followerId = followersBefore.filter(id => !followersAfter.has(id))[0];

        const timelinePostsRef = admin
            .firestore()
            .collection('timeline')
            .doc(followerId)
            .collection('timelinePosts')
            .where("ownerId", "==", userId);

        const querySnapshot = await timelinePostsRef.get();
        querySnapshot.forEach(doc => {
            if (doc.exists) {
                doc.ref.delete();
            }
        });
    }
}

// When post is created, add post to timeline of each follower (of post owner)
exports.onCreatePost = functions.firestore
    .document('posts/{userId}/usersPosts/{postId}')
    .onCreate(async (snapshot, context) => {
        const { userId, postId } = context.params;
        // const postId = context.params.postId;
        const postCreated = snapshot.data();

        // get all followers of post owner
        const userRef = admin
            .firestore()
            .collection('users')
            .doc(userId);

        const followerSnapshot = await userRef.get().then(snapshot => snapshot.get('followers'));

        // add post to each follower's timeline
        followerSnapshot.forEach(follower => {
            console.log('follower id:', follower);
            const followerId = follower;

            admin
                .firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .set(postCreated);
        })
    })

exports.onUpdatePost = functions.firestore
    .document('posts/{userId}/usersPosts/{postId}')
    .onUpdate(async (change, context) => {
        const { userId, postId } = context.params;
        const updatedPost = change.after.data();

        // get all followers of post owner
        const userRef = admin
            .firestore()
            .collection('users')
            .doc(userId);

            const followerSnapshot = await userRef.get().then(snapshot => snapshot.get('followers'));

        // update post in each follower's timeline
        followerSnapshot.forEach(follower => {
            console.log('follower id:', follower);
            const followerId = follower;

            admin
                .firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .get().then(doc => {
                    if (doc.exists) doc.ref.update(updatedPost);
                })
        });
    })

exports.onDeletePost = functions.firestore
    .document('posts/{userId}/usersPosts/{postId}')
    .onDelete(async (snapshot, context) => {
        const { userId, postId } = context.params;

        // get all followers of post owner
        const userRef = admin
            .firestore()
            .collection('users')
            .doc(userId);

        const followerSnapshot = await userRef.get().then(snapshot => snapshot.get('followers'));

        // delete post in each follower's timeline
        followerSnapshot.forEach(follower => {
            console.log('follower id:', follower);
            const followerId = follower;

            admin
                .firestore()
                .collection('timeline')
                .doc(followerId)
                .collection('timelinePosts')
                .doc(postId)
                .get().then(doc => {
                    if (doc.exists) doc.ref.delete();
                })
        });
    })