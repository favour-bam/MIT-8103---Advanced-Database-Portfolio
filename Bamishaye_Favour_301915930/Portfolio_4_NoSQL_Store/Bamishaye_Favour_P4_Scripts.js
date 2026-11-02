const nosql = db.getSiblingDB('nexora_db');

['kyc_profiles', 'audit_events', 'login_sessions'].forEach(function (name) {
    nosql.getCollection(name).drop();
});

// kyc_profiles: one document per customer. The `documents` array holds
// identity documents, and each document type has DIFFERENT fields
// (a passport has an expiry date, a BVN does not). That variety is the
// reason this data does not fit neatly into one SQL table.
// customer_id points at customers.customer_id in PostgreSQL.
nosql.createCollection('kyc_profiles', {
    validator: {
        $jsonSchema: {
            bsonType: 'object',
            required: ['customer_id', 'tier', 'status', 'documents', 'created_at'],
            properties: {
                customer_id: {
                    bsonType: 'number', minimum: 1,
                    description: 'must match customers.customer_id in PostgreSQL'
                },
                tier: { bsonType: 'number', minimum: 1, maximum: 3 },
                status: { enum: ['PENDING', 'VERIFIED', 'REJECTED'] },
                documents: {
                    bsonType: 'array',
                    minItems: 1,
                    items: {
                        bsonType: 'object',
                        required: ['type', 'number'],
                        properties: {
                            type: { enum: ['BVN', 'NIN', 'PASSPORT', 'DRIVERS_LICENCE', 'UTILITY_BILL'] },
                            number: { bsonType: 'string' }
                        }
                    }
                },
                created_at: { bsonType: 'date' }
            }
        }
    },
    validationAction: 'error'
});

// audit_events: an append-only log of what happened. Different event
// types carry different `details`, and new event types can be added
// without altering a table.
nosql.createCollection('audit_events', {
    validator: {
        $jsonSchema: {
            bsonType: 'object',
            required: ['customer_id', 'event_type', 'ts', 'details'],
            properties: {
                customer_id: { bsonType: 'number', minimum: 1 },
                event_type: {
                    enum: ['LOGIN_SUCCESS', 'LOGIN_FAILED', 'PIN_CHANGED',
                        'TRANSFER_INITIATED', 'KYC_UPGRADED', 'FRAUD_FLAG']
                },
                ts: { bsonType: 'date' },
                details: { bsonType: 'object' }
            }
        }
    },
    validationAction: 'error'
});

// login_sessions: short-lived data. A TTL index deletes each document
// automatically one hour after created_at. (Created in step 4's demo.)
nosql.createCollection('login_sessions');

print('Collections now in nexora_db:');
nosql.getCollectionNames().forEach(function (n) { print('  - ' + n); });

// Prove the validator works: this insert is missing required fields and
// has an invalid status, so MongoDB must reject it.
try {
    nosql.kyc_profiles.insertOne({ customer_id: 1, status: 'MAYBE' });
    print('FAIL: the invalid document was accepted');
} catch (e) {
    print('PASS: invalid KYC document rejected -> ' + e.codeName + ' (code ' + e.code + ')');
}const nosql = db.getSiblingDB('nexora_db');
const CUSTOMERS = 5000;
const EVENTS = 100000;
const BATCH = 5000;


// Small deterministic random generator, so every student gets the same
// shape of data (same idea as setseed() in the PostgreSQL seed).
let seedState = 42;
function rnd() {
    seedState = (seedState * 1664525 + 1013904223) % 4294967296;
    return seedState / 4294967296;
}
function randInt(lo, hi) { return lo + Math.floor(rnd() * (hi - lo + 1)); }
function pick(arr) { return arr[Math.floor(rnd() * arr.length)]; }
function digits(n) {
    let s = '';
    for (let i = 0; i < n; i++) s += String(Math.floor(rnd() * 10));
    return s;
}


const NOW = Date.now();
const DAY = 24 * 60 * 60 * 1000;
const CITIES = ['Lagos', 'Abuja', 'Port Harcourt', 'Ibadan', 'Kano', 'Enugu', 'Benin City'];
const STATES = ['Lagos', 'FCT', 'Rivers', 'Oyo', 'Kano', 'Enugu', 'Edo'];
const DEVICES = ['Android', 'iPhone', 'Web'];
const DISCOS = ['Ikeja Electric', 'Eko Disco', 'AEDC', 'PHED'];


nosql.kyc_profiles.deleteMany({});
nosql.audit_events.deleteMany({});


// KYC profiles. The tier decides how many documents exist, and each
// document type has its own fields.
function makeDocument(type) {
    switch (type) {
        case 'BVN':
            return { type: 'BVN', number: digits(11), verified_with: 'NIBSS' };
        case 'NIN':
            return { type: 'NIN', number: digits(11), verified_with: 'NIMC' };
        case 'PASSPORT':
            return {
                type: 'PASSPORT', number: 'A' + digits(8), country: 'NG',
                expiry: new Date(NOW + randInt(200, 3000) * DAY)
            };
        case 'DRIVERS_LICENCE':
            return {
                type: 'DRIVERS_LICENCE', number: 'ABC' + digits(8) + 'XY',
                state_of_issue: pick(STATES), expiry: new Date(NOW + randInt(100, 1500) * DAY)
            };
        default:
            return {
                type: 'UTILITY_BILL', number: 'UB' + digits(8),
                provider: pick(DISCOS), issued_on: new Date(NOW - randInt(5, 80) * DAY)
            };
    }
}


let profiles = [];
for (let id = 1; id <= CUSTOMERS; id++) {
    const r = rnd();
    const tier = r < 0.55 ? 1 : (r < 0.88 ? 2 : 3);
    const docs = [makeDocument('BVN')];
    if (tier >= 2) docs.push(makeDocument(pick(['NIN', 'DRIVERS_LICENCE'])));
    if (tier >= 3) {
        docs.push(makeDocument(pick(['PASSPORT', 'DRIVERS_LICENCE'])));
        docs.push(makeDocument('UTILITY_BILL'));
    }
    const profile = {
        customer_id: id,
        tier: tier,
        status: rnd() < 0.93 ? 'VERIFIED' : (rnd() < 0.5 ? 'PENDING' : 'REJECTED'),
        documents: docs,
        created_at: new Date(NOW - randInt(30, 700) * DAY)
    };
    // Optional fields: only SOME documents have them. A SQL table would
    // need a mostly-NULL column; here the field simply does not exist.
    if (tier === 3) profile.risk_notes = 'Enhanced due diligence completed';
    if (rnd() < 0.2) profile.devices = [{ platform: pick(DEVICES), first_seen: new Date(NOW - randInt(1, 400) * DAY) }];
    profiles.push(profile);
}
nosql.kyc_profiles.insertMany(profiles);
profiles = null;
print('kyc_profiles inserted: ' + nosql.kyc_profiles.countDocuments({}));


// Audit events over the last 90 days. `details` differs per event type.
function makeEvent() {
    const customer_id = randInt(1, CUSTOMERS);
    const ts = new Date(NOW - Math.floor(rnd() * 90 * DAY));
    const r = rnd();
    let event_type, details;
    if (r < 0.40) {
        event_type = 'LOGIN_SUCCESS';
        details = {
            ip: '102.89.' + randInt(0, 255) + '.' + randInt(1, 254),
            device: pick(DEVICES), city: pick(CITIES)
        };
    } else if (r < 0.55) {
        event_type = 'LOGIN_FAILED';
        details = {
            ip: '41.58.' + randInt(0, 255) + '.' + randInt(1, 254),
            reason: pick(['WRONG_PIN', 'WRONG_PIN', 'DEVICE_NOT_RECOGNISED', 'ACCOUNT_LOCKED'])
        };
    } else if (r < 0.60) {
        event_type = 'PIN_CHANGED';
        details = { channel: pick(['APP', 'USSD']) };
    } else if (r < 0.90) {
        event_type = 'TRANSFER_INITIATED';
        details = {
            reference: 'ref-' + digits(10),
            amount: NumberDecimal((randInt(500, 500000) / 100).toFixed(2)),
            channel: pick(['APP', 'USSD', 'WEB'])
        };
    } else if (r < 0.95) {
        event_type = 'KYC_UPGRADED';
        const from = randInt(1, 2);
        details = { from_tier: from, to_tier: from + 1 };
    } else {
        event_type = 'FRAUD_FLAG';
        details = {
            rule: pick(['VELOCITY', 'NEW_DEVICE_LARGE_AMOUNT', 'MANY_FAILED_LOGINS']),
            score: randInt(40, 99)
        };
    }
    return { customer_id: customer_id, event_type: event_type, ts: ts, details: details };
}


for (let done = 0; done < EVENTS; done += BATCH) {
    const batch = [];
    for (let i = 0; i < BATCH; i++) batch.push(makeEvent());
    nosql.audit_events.insertMany(batch, { ordered: false });
    print('audit_events inserted so far: ' + (done + BATCH));
}


// Verification
print('');
print('=== Verification ===');
print('kyc_profiles : ' + nosql.kyc_profiles.countDocuments({}) + '  (expected ' + CUSTOMERS + ')');
print('audit_events : ' + nosql.audit_events.countDocuments({}) + '  (expected ' + EVENTS + ')');
print('Events by type:');
nosql.audit_events.aggregate([
    { $group: { _id: '$event_type', n: { $sum: 1 } } },
    { $sort: { n: -1 } }
]).forEach(function (d) { print('  ' + d._id + ': ' + d.n); });
print('Sample KYC profile (tier 3):');
printjson(nosql.kyc_profiles.findOne({ tier: 3 }));// Portfolio 4 - Step 3: CRUD operations and aggregation pipelines.
// Requires steps 1 and 2. Re-runnable (it cleans up its own test customer).


const nosql = db.getSiblingDB('nexora_db');
const TEST_ID = 999999;   // a customer that exists only for this demo
nosql.kyc_profiles.deleteMany({ customer_id: TEST_ID });


print('############ CRUD ############');


// ---- CREATE -----------------------------------------------------------
print('\n--- CREATE: onboard a new customer with a passport (nested fields)');
nosql.kyc_profiles.insertOne({
    customer_id: TEST_ID,
    tier: 2,
    status: 'PENDING',
    documents: [
        { type: 'BVN', number: '22212345678', verified_with: 'NIBSS' },
        { type: 'PASSPORT', number: 'A12345678', country: 'NG', expiry: new Date('2031-05-01') }
    ],
    created_at: new Date()
});
printjson(nosql.kyc_profiles.findOne({ customer_id: TEST_ID }, { _id: 0 }));


// ---- READ -------------------------------------------------------------
print('\n--- READ: tier 3 customers who hold a PASSPORT (query inside an array)');
print('count = ' + nosql.kyc_profiles.countDocuments({ tier: 3, 'documents.type': 'PASSPORT' }));


print('\n--- READ: passports expiring in the next 365 days (nested field filter)');
print('count = ' + nosql.kyc_profiles.countDocuments({
    documents: { $elemMatch: { type: 'PASSPORT', expiry: { $lt: new Date(Date.now() + 365 * 86400000) } } }
}));


print('\n--- READ: last 3 audit events for customer 1001 (newest first)');
nosql.audit_events.find({ customer_id: 1001 }, { _id: 0 }).sort({ ts: -1 }).limit(3)
    .forEach(function (d) { printjson(d); });


// ---- UPDATE -----------------------------------------------------------
print('\n--- UPDATE: verify the customer and upgrade to tier 3 (set)andaddadocument(push)');
nosql.kyc_profiles.updateOne(
    { customer_id: TEST_ID },
    {
        $set: { status: 'VERIFIED', tier: 3 },
        $push: { documents: { type: 'UTILITY_BILL', number: 'UB99999999', provider: 'Eko Disco', issued_on: new Date() } }
    }
);
const updated = nosql.kyc_profiles.findOne({ customer_id: TEST_ID });
print('status=' + updated.status + ', tier=' + updated.tier + ', documents=' + updated.documents.length);


print('\n--- UPDATE: record the change in the audit log (append-only: we insert, never edit)');
nosql.audit_events.insertOne({
    customer_id: TEST_ID, event_type: 'KYC_UPGRADED', ts: new Date(),
    details: { from_tier: 2, to_tier: 3 }
});


// ---- DELETE -----------------------------------------------------------
print('\n--- DELETE: remove the demo customer profile');
const del = nosql.kyc_profiles.deleteOne({ customer_id: TEST_ID });
print('deleted = ' + del.deletedCount);
nosql.audit_events.deleteMany({ customer_id: TEST_ID });   // clean up the demo event only


print('\n############ AGGREGATION ############');


// ---- 1. Events per type, last 30 days --------------------------------
print('\n--- Aggregation 1: events per type in the last 30 days');
nosql.audit_events.aggregate([
    { $match: { ts: { $gte: new Date(Date.now() - 30 * 86400000) } } },
    { $group: { _id: '$event_type', events: { $sum: 1 } } },
    { $sort: { events: -1 } }
]).forEach(function (d) { print('  ' + d._id + ': ' + d.events); });


// ---- 2. Daily transfer-initiated amounts ------------------------------
print('\n--- Aggregation 2: total TRANSFER_INITIATED amount per day (latest 5 days)');
nosql.audit_events.aggregate([
    { $match: { event_type: 'TRANSFER_INITIATED' } },
    {
        $group: {
            _id: { $dateToString: { format: '%Y-%m-%d', date: '$ts' } },
            transfers: { $sum: 1 },
            total_amount: { $sum: '$details.amount' }
        }
    },
    { $sort: { _id: -1 } },
    { $limit: 5 }
]).forEach(function (d) {
    print('  ' + d._id + '  transfers=' + d.transfers + '  total=' + d.total_amount);
});


// ---- 3. $lookup: join audit events to KYC profile ---------------------
print('\n--- Aggregation 3: top 5 customers by failed logins, with their KYC tier ($lookup = a JOIN)');
nosql.audit_events.aggregate([
    { $match: { event_type: 'LOGIN_FAILED' } },
    { $group: { _id: '$customer_id', failed_logins: { $sum: 1 } } },
    { $sort: { failed_logins: -1, _id: 1 } },
    { $limit: 5 },
    { $lookup: { from: 'kyc_profiles', localField: '_id', foreignField: 'customer_id', as: 'kyc' } },
    { $unwind: '$kyc' },
    { $project: { _id: 0, customer_id: '$_id', failed_logins: 1, tier: '$kyc.tier', status: '$kyc.status' } }
]).forEach(function (d) { printjson(d); });


// ---- 4. Documents per tier -------------------------------------------
print('\n--- Aggregation 4: average number of documents per KYC tier ($size)');
nosql.kyc_profiles.aggregate([
    { $group: { _id: '$tier', customers: { $sum: 1 }, avg_documents: { $avg: { $size: '$documents' } } } },
    { $sort: { _id: 1 } }
]).forEach(function (d) { print('  tier ' + d._id + ': customers=' + d.customers + ', avg documents=' + d.avg_documents); });// Portfolio 4 - Step 4: indexes, explain() and a TTL index.
// Same idea as Portfolio 2: measure BEFORE the index, create it, measure AFTER.
// Requires steps 1 and 2. Re-runnable.

const nosql = db.getSiblingDB('nexora_db');

// Walk an explain plan and list every stage name, e.g. [ 'LIMIT', 'FETCH', 'IXSCAN' ].
function stageNames(plan) {
    const names = [];
    (function walk(node) {
        if (!node) return;
        if (node.stage) names.push(node.stage);
        if (node.inputStage) walk(node.inputStage);
        if (node.inputStages) node.inputStages.forEach(walk);
        if (node.queryPlan) walk(node.queryPlan);
    })(plan.queryPlanner.winningPlan);
    return names;
}

function report(label, cursor) {
    const ex = cursor.explain('executionStats');
    const s = ex.executionStats;
    print('  [' + label + ']');
    print('    plan stages        : ' + stageNames(ex).join(' > '));
    print('    documents examined : ' + s.totalDocsExamined);
    print('    index keys examined: ' + s.totalKeysExamined);
    print('    documents returned : ' + s.nReturned);
    print('    execution time (ms): ' + s.executionTimeMillis);
}

// Start from a clean slate: drop every index except the default _id one.
nosql.audit_events.dropIndexes();
nosql.kyc_profiles.dropIndexes();

// The three queries we care about.
const q1 = function () { return nosql.audit_events.find({ customer_id: 1001 }).sort({ ts: -1 }).limit(20); };
const q2 = function () { return nosql.audit_events.find({ event_type: 'FRAUD_FLAG', ts: { $gte: new Date(Date.now() - 7 * 86400000) } }); };
const q3 = function () { return nosql.kyc_profiles.find({ customer_id: 2500 }); };

print('############ BEFORE indexes ############');
print('Q1: latest 20 events for customer 1001'); report('before', q1());
print('Q2: FRAUD_FLAG events in the last 7 days'); report('before', q2());
print('Q3: KYC profile for customer 2500'); report('before', q3());

// Create indexes
print('\n############ Creating indexes ############');
// Q1: equality on customer_id, then newest-first on ts. One compound index serves
// both the filter and the sort (no in-memory sort needed).
print(nosql.audit_events.createIndex({ customer_id: 1, ts: -1 }, { name: 'idx_audit_customer_ts' }));
// Q2: equality on event_type, then a range on ts.
print(nosql.audit_events.createIndex({ event_type: 1, ts: -1 }, { name: 'idx_audit_type_ts' }));
// Q3: exactly one KYC profile per customer, so the index is UNIQUE. This is the
// closest MongoDB gets to a relational PRIMARY KEY / UNIQUE constraint.
print(nosql.kyc_profiles.createIndex({ customer_id: 1 }, { unique: true, name: 'uq_kyc_customer' }));

print('\n############ AFTER indexes ############');
print('Q1: latest 20 events for customer 1001'); report('after', q1());
print('Q2: FRAUD_FLAG events in the last 7 days'); report('after', q2());
print('Q3: KYC profile for customer 2500'); report('after', q3());

// The unique index also protects us: a second profile for the same customer fails.
print('\n############ Unique index in action ############');
try {
    nosql.kyc_profiles.insertOne({
        customer_id: 1, tier: 1, status: 'PENDING',
        documents: [{ type: 'BVN', number: '11111111111' }], created_at: new Date()
    });
    print('FAIL: duplicate profile accepted');
} catch (e) {
    print('PASS: duplicate customer_id rejected -> ' + e.codeName + ' (code ' + e.code + ')');
}

// TTL index: documents delete themselves. Right for sessions, WRONG for the
// audit log (audit records must be kept), which is why only login_sessions has it.
print('\n############ TTL index on login_sessions ############');
nosql.login_sessions.deleteMany({});
nosql.login_sessions.createIndex({ created_at: 1 }, { expireAfterSeconds: 3600, name: 'ttl_session_1h' });
nosql.login_sessions.insertMany([
    { customer_id: 1001, token: 'tok-recent', created_at: new Date() },
    { customer_id: 1002, token: 'tok-old', created_at: new Date(Date.now() - 2 * 3600 * 1000) }
]);
print('Inserted 2 sessions, one already older than the 1 hour limit.');
print('MongoDB checks TTL indexes about once a minute, so the old one disappears shortly.');
print('Run this to see it: mongosh "$MONGODB_URI" --eval "db.getSiblingDB(\'nairapay_nosql\').login_sessions.find()"');

print('\n############ Index sizes ############');
['audit_events', 'kyc_profiles'].forEach(function (c) {
    try {
        const st = nosql.getCollection(c).stats();
        print(c + ': data=' + (st.size / 1048576).toFixed(1) + ' MB, indexes=' + (st.totalIndexSize / 1048576).toFixed(1) + ' MB');
    } catch (e) {
        print(c + ': stats not available here (' + e.message + '). Use Atlas > Collections > Indexes tab instead.');
    }
});

