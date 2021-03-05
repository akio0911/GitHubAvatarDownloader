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

    private enum State {
        case idle
        case loading
    }

    private var state: State = .idle

    @IBOutlet private weak var usernameTextField: UITextField!
    @IBOutlet private weak var profileImageView: UIImageView!

    @IBOutlet private weak var activityIndicatorView: UIActivityIndicatorView!

    @IBOutlet private weak var downloadButton: UIButton!

    @IBAction func didTapDownload(_ sender: Any) {
        state = .loading
        updateUI()

        UserDownloader().downloadUser(
            userName: usernameTextField.text ?? "",
            success: { user in
                ImageDownloader().download(
                    url: user.avatarURL,
                    success: { image in
                        DispatchQueue.main.async { [weak self] in
                            self?.state = .idle
                            self?.updateUI()

                            self?.profileImageView.image = image
                        }
                    },
                    error: { [weak self] in
                        DispatchQueue.main.async { [weak self] in
                            self?.state = .idle
                            self?.updateUI()
                        }
                    }
                )
            },
            error: { [weak self] in
                DispatchQueue.main.async { [weak self] in
                    self?.state = .idle
                    self?.updateUI()
                }
            }
        )
    }

    private func updateUI() {
        downloadButton.isEnabled = {
            switch state {
            case .idle:
                return true
            case .loading:
                return false
            }
        }()

        switch state {
        case .idle:
            activityIndicatorView.stopAnimating()
        case .loading:
            activityIndicatorView.startAnimating()
        }
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
        URLSession.shared.dataTask(
            with: url,
            completionHandler: { data, response, err in
                if err != nil {
                    error()
                    return
                }

                guard let data = data,
                      let response = response as? HTTPURLResponse else {

                    error()
                    return
                }

                switch response.statusCode {
                case 200:
                    success(data)
                default:
                    error()
                }
            }
        ).resume()
    }
}
