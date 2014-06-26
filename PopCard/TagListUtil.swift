import Foundation

// Utility functions for working with objects of type Array<Tag>, because it doesn't seem to be possible to extend or
// subclass this type.
//
class TagListUtil {

    // Return whether a list of tags contains a tag with a specific ID.
    //
    class func contains(tagID: String, tags: Array<Tag>) -> Bool {
        for tag in tags {
            if tag.id == tagID {
                return true
            }
        }
        return false
    }
    
    // Return the relative complement of A in B. The set of elements in B, but not in A.
    //
    class func relativeComplement(b: Tag[], a: Tag[]) -> Tag[] {
        var result = Tag[]()
        for bTag in b {
            var found = false
            for aTag in a {
                if bTag.id == aTag.id {
                    found = true
                }
            }
            if !found {
                result.append(bTag)
            }
        }
        return result
    }
}