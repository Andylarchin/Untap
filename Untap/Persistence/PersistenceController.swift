import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    static let appGroupID = "group.com.andy.Untap"

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        let model = Self.createModel()
        container = NSPersistentContainer(name: "Untap", managedObjectModel: model)

        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        } else if let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: Self.appGroupID) {
            let storeURL = appGroupURL.appendingPathComponent("Untap.sqlite")
            let description = NSPersistentStoreDescription(url: storeURL)
            container.persistentStoreDescriptions = [description]
        }

        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                print("Core Data load error: \(error), \(error.userInfo)")
            }
        }

        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func save() {
        let context = viewContext
        guard context.hasChanges else { return }
        do {
            try context.save()
        } catch {
            print("Core Data save error: \(error)")
        }
    }

    private static func createModel() -> NSManagedObjectModel {
        let model = NSManagedObjectModel()

        // CDBlockSession entity
        let sessionEntity = NSEntityDescription()
        sessionEntity.name = "CDBlockSession"
        sessionEntity.managedObjectClassName = "CDBlockSession"

        let sessionId = NSAttributeDescription()
        sessionId.name = "id"
        sessionId.attributeType = .UUIDAttributeType
        sessionId.isOptional = true

        let sessionStartDate = NSAttributeDescription()
        sessionStartDate.name = "startDate"
        sessionStartDate.attributeType = .dateAttributeType
        sessionStartDate.isOptional = true

        let sessionEndDate = NSAttributeDescription()
        sessionEndDate.name = "endDate"
        sessionEndDate.attributeType = .dateAttributeType
        sessionEndDate.isOptional = true

        let sessionIsActive = NSAttributeDescription()
        sessionIsActive.name = "isActive"
        sessionIsActive.attributeType = .booleanAttributeType
        sessionIsActive.defaultValue = false
        sessionIsActive.isOptional = true

        // CDBlockAttempt entity
        let attemptEntity = NSEntityDescription()
        attemptEntity.name = "CDBlockAttempt"
        attemptEntity.managedObjectClassName = "CDBlockAttempt"

        let attemptId = NSAttributeDescription()
        attemptId.name = "id"
        attemptId.attributeType = .UUIDAttributeType
        attemptId.isOptional = true

        let attemptAppIdentifier = NSAttributeDescription()
        attemptAppIdentifier.name = "appIdentifier"
        attemptAppIdentifier.attributeType = .stringAttributeType
        attemptAppIdentifier.isOptional = true

        let attemptAppDisplayName = NSAttributeDescription()
        attemptAppDisplayName.name = "appDisplayName"
        attemptAppDisplayName.attributeType = .stringAttributeType
        attemptAppDisplayName.isOptional = true

        let attemptTimestamp = NSAttributeDescription()
        attemptTimestamp.name = "timestamp"
        attemptTimestamp.attributeType = .dateAttributeType
        attemptTimestamp.isOptional = true

        // Relationships
        let sessionToAttempts = NSRelationshipDescription()
        sessionToAttempts.name = "attempts"
        sessionToAttempts.destinationEntity = attemptEntity
        sessionToAttempts.isOptional = true
        sessionToAttempts.deleteRule = .cascadeDeleteRule
        sessionToAttempts.maxCount = 0 // to-many

        let attemptToSession = NSRelationshipDescription()
        attemptToSession.name = "session"
        attemptToSession.destinationEntity = sessionEntity
        attemptToSession.isOptional = true
        attemptToSession.deleteRule = .nullifyDeleteRule
        attemptToSession.maxCount = 1 // to-one

        sessionToAttempts.inverseRelationship = attemptToSession
        attemptToSession.inverseRelationship = sessionToAttempts

        sessionEntity.properties = [sessionId, sessionStartDate, sessionEndDate, sessionIsActive, sessionToAttempts]
        attemptEntity.properties = [attemptId, attemptAppIdentifier, attemptAppDisplayName, attemptTimestamp, attemptToSession]

        model.entities = [sessionEntity, attemptEntity]
        return model
    }
}

// MARK: - CDBlockSession
@objc(CDBlockSession)
public class CDBlockSession: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var startDate: Date?
    @NSManaged public var endDate: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var attempts: NSSet?
}

extension CDBlockSession {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDBlockSession> {
        return NSFetchRequest<CDBlockSession>(entityName: "CDBlockSession")
    }
}

// MARK: - CDBlockAttempt
@objc(CDBlockAttempt)
public class CDBlockAttempt: NSManagedObject {
    @NSManaged public var id: UUID?
    @NSManaged public var appIdentifier: String?
    @NSManaged public var appDisplayName: String?
    @NSManaged public var timestamp: Date?
    @NSManaged public var session: CDBlockSession?
}

extension CDBlockAttempt {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDBlockAttempt> {
        return NSFetchRequest<CDBlockAttempt>(entityName: "CDBlockAttempt")
    }
}
