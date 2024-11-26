//
//  SkillsManager.swift
//  BarterUp
//
//  Created by Ben Gmach on 11/26/24.
//

import Foundation

class SkillsManager {
    static let shared = SkillsManager()
    
    let skillCategories: [String: [String]] = [
        "Sports & Fitness": [
            "Basketball",
            "Soccer",
            "Tennis",
            "Swimming",
            "Yoga",
            "Personal Training",
            "Running",
            "Dance",
            "Martial Arts"
        ],
        "Technology": [
            "iOS Development",
            "Web Development",
            "Python",
            "JavaScript",
            "Data Analysis",
            "Graphic Design",
            "UI/UX Design",
            "Digital Marketing"
        ],
        "Arts & Music": [
            "Guitar",
            "Piano",
            "Singing",
            "Painting",
            "Drawing",
            "Photography",
            "Video Editing",
            "Animation"
        ],
        "Education": [
            "Math Tutoring",
            "Science Tutoring",
            "English Tutoring",
            "Test Prep",
            "Language Teaching",
            "History",
            "Writing"
        ],
        "Business": [
            "Marketing",
            "Accounting",
            "Public Speaking",
            "Project Management",
            "Sales",
            "Entrepreneurship",
            "Social Media Management"
        ],
        "Lifestyle": [
            "Cooking",
            "Baking",
            "Gardening",
            "Interior Design",
            "Fashion Styling",
            "Nutrition",
            "Personal Finance"
        ],
        "Crafts": [
            "Woodworking",
            "Knitting",
            "Sewing",
            "Pottery",
            "Jewelry Making",
            "DIY Projects",
            "3D Printing"
        ],
        "Languages": [
            "Spanish",
            "French",
            "Chinese",
            "Japanese",
            "German",
            "Italian",
            "Korean"
        ]
    ]
    
    // Helper method to get all skills in a category
    func getSkills(for category: String) -> [String] {
        return skillCategories[category] ?? []
    }
    
    // Helper method to get all categories
    func getAllCategories() -> [String] {
        return Array(skillCategories.keys).sorted()
    }
    
    // Helper method to find which category a skill belongs to
    func getCategory(for skill: String) -> String? {
        for (category, skills) in skillCategories {
            if skills.contains(skill) {
                return category
            }
        }
        return nil
    }
}
