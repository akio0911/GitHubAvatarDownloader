//
//  ViewController.swift
//  LiveCoding
//
//  Created by akio0911youtube on 2021/03/03.
//

import UIKit

struct GitHubUser: Decodable {
    let name: String
    let avatarURL: URL
    enum CodingKeys: String, CodingKey {
        case name = "login"
        case avatarURL = "avatar_url"
    }
}

class ViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var profileImageView: UIImageView!

    @IBAction func didTapDownload(_ sender: Any) {
        UserDownloader().downloadUser(
            userName: usernameTextField.text ?? "",
            success: { user in
                ImageDownloader().download(
                    url: user.avatarURL,
                    success: { image in
                        DispatchQueue.main.async { [weak self] in
                            self?.profileImageView.image = image
                        }
                    },
                    error: {}
                )
            },
            error: {}
        )
    }
}

struct UserDownloader {
    func downloadUser(
        userName: String,
        success: @escaping (GitHubUser) -> Void,
        error: @escaping () -> Void) {

        guard let url = URL(string: "https://api.github.com/users/\(userName)") else {
            error()
            return
        }

        DataDownloader().download(
            url: url,
            success: { data in
                let decoder = JSONDecoder()
                if let user = try? decoder.decode(GitHubUser.self, from: data) {
                    success(user)
                } else {
                    error()
                }
            },
            error: error
        )
    }
}

struct ImageDownloader {
    func download(url: URL,
                  success: @escaping (UIImage) -> Void,
                  error: @escaping () -> Void
    ) {
        DispatchQueue.global().async {
            DataDownloader().download(
                url: url,
                success: { data in
                    if let image = UIImage(data: data) {
                        success(image)
                    } else {
                        error()
                    }
                },
                error: error
            )
        }
    }
}

struct DataDownloader {
    func download(url: URL,
                  success: @escaping (Data) -> Void,
                  error: @escaping () -> Void
                  ) {
        DispatchQueue.global().async {
            if let data = try? Data(contentsOf: url, options: []) {
                success(data)
            } else {
                error()
            }
        }
    }
}
