## Summary query. Replace the dates as needed.

```
db.getCollection('thumbs').aggregate([
    {
        $match: {
            createdAt: { $gte : new ISODate("2016-12-12T00:00:00Z"), $lt: ISODate("2016-12-13T00:00:00.000Z")},
            serviceId: 'your-service-id',
            uniqueId: { $regex: /^[^_]+$/ }
        }
    },
    {
        $project: {
            'agent.name': 1,
            positive: { $cond: [{$gte: [ '$rating', 0]}, 1, 0]},
            negative: { $cond: [{$lt: [ '$rating', 0]}, 1, 0]}
        }
    },
    {
        $group: {
            _id: '$agent.name',
            positive: {$sum: '$positive'},
            negative: {$sum: '$negative'}
        }
    }
])
```
