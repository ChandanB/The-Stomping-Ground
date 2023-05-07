//
//  BlogModel.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 5/2/23.
//

import Foundation
import FirebaseFirestoreSwift

// MARK: - Welcome3
struct Welcome3: Codable {
    let website: Website?
    let websiteSettings: WebsiteSettings?
    let collection: Collection?
    let shoppingCart: ShoppingCart?
    let shareButtons: ShareButtons?
    let showCart: Bool?
    let localizedStrings: LocalizedStrings?
    let userAccountsContext: UserAccountsContext?
    let template: Template?
    let uiextensions: Uiextensions?
    let empty, emptyFolder, calendarView: Bool?
    let pagination: Pagination?
    let items: [Item]?
}

// MARK: - Collection
struct Collection: Codable {
    let id: String?
    let websiteID: String?
    let video: Video
    let backgroundSource: Int?
    let enabled, starred: Bool?
    let type, ordering: Int?
    let title, navigationTitle, urlID: String?
    let itemCount, updatedOn: Int?
    let collectionDescription: String?
    let publicCommentCount, pageSize: Int?
    let features: Features
    let folder, dropdown: Bool?
    let tags, categories: [String]?
    let homepage: Bool?
    let typeName, regionName: String?
    let synchronizing, categoryPagesSEOHidden, tagPagesSEOHidden, draft: Bool?
    let fullUrl, typeLabel: String?
    let passwordProtected: Bool?
    let pagePermissionType: Int?
}

// MARK: - Features
struct Features: Codable {
    let relatedItems, productQuickView: ProductQuickView
}

// MARK: - ProductQuickView
struct ProductQuickView: Codable {
    let isEnabled: Bool?
}

enum ID {
    case the58454Bb0C03026C6174B84Fe
}

// MARK: - Video
struct Video: Codable {
    let playbackSpeed, zoom: Int?
}

// MARK: - Item
struct Item: Codable, Identifiable {
    var id: String?
    var collectionID: String?
    var recordType, addedOn, updatedOn: Int?
    var starred, passthrough: Bool?
    var tags, categories: [String]?
    var workflowState, publishOn: Int
    var authorID, systemDataID, systemDataVariants: String?
    var systemDataSourceType: String?
    var filename: String?
    var mediaFocalPoint: MediaFocalPoint?
    var colorData: ColorData?
    var urlID: String?
    var sourceUrl: String?
    var title, body: String
    var excerpt: String
    var location: ItemLocation?
    var customContent: String?
    var likeCount, commentCount, publicCommentCount, commentState: Int
    var unsaved: Bool?
    var author: Author
    var fullUrl: String?
    var assetUrl: String?
    var contentType: String?
    var items: [Item]?
    var pushedServices, pendingPushedServices: ShippingLocation?
    var seoData: SEOData?
    var recordTypeLabel: String?
    var originalSize: String?
}

// MARK: - Author
struct Author: Codable {
    let id, displayName, firstName, lastName: String
    let avatarUrl: String?
    let bio: String?
    let avatarAssetUrl: String?
    let avatarID, websiteUrl: String?
}

// MARK: - ColorData
struct ColorData: Codable {
    let topLeftAverage, topRightAverage, bottomLeftAverage, bottomRightAverage: String?
    let centerAverage, suggestedBgColor: String?
}

enum ContentType {
    case imageJPEG
    case imagePNG
}

// MARK: - ItemLocation
struct ItemLocation: Codable {
    let mapZoom, mapLat, mapLng, markerLat: Double
    let markerLng: Double
    let addressTitle, addressLine1, addressLine2, addressCountry: String?
}

// MARK: - MediaFocalPoint
struct MediaFocalPoint: Codable {
    let x, y: Double
    let source: Int?
}

// MARK: - ShippingLocation
struct ShippingLocation: Codable {
}

enum RecordTypeLabel {
    case text
}

// MARK: - SEOData
struct SEOData: Codable {
    let seoTitle, seoDescription: String?
    let seoHidden: Bool?
    let seoImageID: String?
}

enum SystemDataSourceType {
    case jpg
    case png
}

// MARK: - LocalizedStrings
struct LocalizedStrings: Codable {
    let prev, next, cart, back: String?
    let search, scroll, hours, mon: String?
    let tue, wed, thu, fri: String?
    let sat, sun, signIn, myAccount: String?
    let intro, footerTopBlocks, footerMiddleBlocks, footerBottomBlocks: String?
    let newer, older, categoryFilter, tagFilter: String?
    let authorFilter, readMore: String?
    let comments: Comments
    let leaveComment, noPosts: String?
}

// MARK: - Comments
struct Comments: Codable {
    let one, other: String?
}

// MARK: - Pagination
struct Pagination: Codable {
    let nextPage: Bool?
    let nextPageOffset: Int?
    let nextPageUrl: String?
    let pageSize: Int?
}

// MARK: - ShareButtons
struct ShareButtons: Codable {
    let twitter, facebook, reddit, tumblr: Bool?
    let google, pinterest, linkedin: Bool?
}

// MARK: - ShoppingCart
struct ShoppingCart: Codable {
    let websiteID: String?
    let created: Int?
    let shippingLocation: ShippingLocation
    let cartType: Int?
    let subtotalCents, taxCents, shippingCostCents, discountCents: Int?
    let giftCardRedemptionTotalCents, grandTotalCents, amountDueCents, totalQuantity: Int?
    let purelyDigital, hasDigital, requiresShipping: Bool?
}

// MARK: - Template
struct Template: Codable {
    let mobileStylesEnabled: Bool?
}

// MARK: - Uiextensions
struct Uiextensions: Codable {
    let productBadge, productBody, productBadgeMobile, productBodyMobile: String?
    let productCollectionItem: String?
    let scriptsEnabled: Bool?
}

// MARK: - UserAccountsContext
struct UserAccountsContext: Codable {
    let showSignInLink: Bool?
}

// MARK: - Website
struct Website: Codable {
    let id, identifier: String?
    let websiteType, contentModifiedOn: Int?
    let cloneable, hasBeenCloneable: Bool?
    let siteStatus: ShippingLocation
    let language, timeZone: String?
    let machineTimeZoneOffset, timeZoneOffset: Int?
    let timeZoneAbbr, siteTitle, siteTagLine, siteDescription: String?
    let location: WebsiteLocation
    let logoImageID, socialLogoImageID: String?
    let shareButtonOptions: [String: Bool]?
    let logoImageUrl, socialLogoImageUrl: String?
    let authenticUrl, internalUrl, baseUrl: String?
    let primaryDomain: String?
    let sslSetting: Int?
    let isHstsEnabled: Bool?
    let socialAccounts: [SocialAccount]
    let typekitID: String?
    let statsMigrated, imageMetadataProcessingEnabled: Bool?
    let screenshotID: String?
    let captchaSettings: CAPTCHASettings
    let showOwnerLogin: Bool?
}

// MARK: - CAPTCHASettings
struct CAPTCHASettings: Codable {
    let enabledForDonations: Bool?
}

// MARK: - WebsiteLocation
struct WebsiteLocation: Codable {
    let addressLine1, addressLine2, addressCountry: String?
}

// MARK: - SocialAccount
struct SocialAccount: Codable {
    let serviceID: Int?
    let userID: String?
    let screenname: String?
    let addedOn: Int?
    let profileUrl: String?
    let iconUrl: String?
    let metaData: MetaData?
    let iconEnabled: Bool?
    let serviceName: String?
}

// MARK: - MetaData
struct MetaData: Codable {
    let service: String?
}

// MARK: - WebsiteSettings
struct WebsiteSettings: Codable {
    let id, websiteID: String?
    let country, state: String?
    let simpleLikingEnabled: Bool?
    let mobileInfoBarSettings: MobileInfoBarSettings
    let announcementBarSettings: AnnouncementBarSettings
    let popupOverlaySettings: PopupOverlaySettings
    let commentLikesAllowed, commentAnonAllowed, commentThreaded, commentApprovalRequired: Bool?
    let commentAvatarsOn: Bool?
    let commentSortType, commentFlagThreshold: Int?
    let commentFlagsAllowed, commentEnableByDefault: Bool?
    let commentDisableAfterDaysDefault: Int?
    let disqusShortname, collectionTitleFormat, itemTitleFormat: String?
    let commentsEnabled, uiComponentRegistrationsFlag, scriptRegistrationsFlag, bundleEligible: Bool?
    let businessHours: BusinessHours
    let storeSettings: StoreSettings
    let useEscapeKeyToLogin: Bool?
    let ssBadgeType, ssBadgePosition, ssBadgeVisibility, ssBadgeDevices: Int?
    let pinterestOverlayOptions: PinterestOverlayOptions
    let ampEnabled, seoHidden: Bool?
    let userAccountsSettings: UserAccountsSettings
    let contactEmail, contactPhoneNumber: String?
}

// MARK: - AnnouncementBarSettings
struct AnnouncementBarSettings: Codable {
    let style: Int?
    let text: String?
    let clickthroughUrl: ClickthroughUrl?
}

// MARK: - ClickthroughUrl
struct ClickthroughUrl: Codable {
    let Url: String?
    let newWindow: Bool?
}

// MARK: - BusinessHours
struct BusinessHours: Codable {
    let monday, tuesday, wednesday, thursday: Day
    let friday, saturday, sunday: Day
}

// MARK: - Day
struct Day: Codable {
    let text: String?
    let ranges: [ShippingLocation]
}

// MARK: - MobileInfoBarSettings
struct MobileInfoBarSettings: Codable {
    let style: Int?
    let isContactEmailEnabled, isContactPhoneNumberEnabled, isLocationEnabled, isBusinessHoursEnabled: Bool?
}

// MARK: - PinterestOverlayOptions
struct PinterestOverlayOptions: Codable {
    let mode, size, shape: String?
}

// MARK: - PopupOverlaySettings
struct PopupOverlaySettings: Codable {
    let style: Int?
    let showOnScroll: Bool?
    let scrollPercentage: Int?
    let showOnTimer: Bool?
    let timerDelay: Int?
    let showUntilSignup: Bool?
    let displayFrequency: Int?
    let enableMobile: Bool?
    let showOnAllPages: Bool?
    let version: Int?
}

// MARK: - StoreSettings
struct StoreSettings: Codable {
    let returnPolicy, termsOfService, privacyPolicy: String?
    let expressCheckout: Bool?
    let continueShoppingLinkUrl: String?
    let useLightCart, showNoteField: Bool?
    let shippingCountryDefaultValue: String?
    let billToShippingDefaultValue, showShippingPhoneNumber, isShippingPhoneRequired, showBillingPhoneNumber: Bool?
    let isBillingPhoneRequired: Bool?
    let currenciesSupported: [String]?
    let defaultCurrency, selectedCurrency: String?
    let measurementStandard: Int?
    let showCustomCheckoutForm, checkoutPageMarketingOptInEnabled, enableMailingListOptInByDefault, sameAsRetailLocation: Bool?
    let merchandisingSettings: MerchandisingSettings
    let isLive, multipleQuantityAllowedForServices: Bool?
}

// MARK: - MerchandisingSettings
struct MerchandisingSettings: Codable {
    let scarcityEnabledOnProductItems, scarcityEnabledOnProductBlocks: Bool?
    let scarcityMessageType: String?
    let scarcityThreshold: Int?
    let multipleQuantityAllowedForServices, restockNotificationsEnabled, restockNotificationsMailingListSignUpEnabled, relatedProductsEnabled: Bool?
    let relatedProductsOrdering: String?
    let soldOutVariantsDropdownDisabled, productComposerOptedIn, productComposerABTestOptedOut, productReviewsEnabled: Bool?
    let displayImportedProductReviewsEnabled, hasOptedToCollectNativeReviews: Bool?
}

// MARK: - UserAccountsSettings
struct UserAccountsSettings: Codable {
    let loginAllowed, signupAllowed: Bool?
}
