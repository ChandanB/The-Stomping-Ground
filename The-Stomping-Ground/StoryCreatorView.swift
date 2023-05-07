//
//  StoryCreatorView.swift
//  The-Stomping-Ground
//
//  Created by Chandan Brown on 5/7/23.
//

import Foundation
import SwiftUI
import AVKit
import AVFoundation
import PhotosUI
import CoreMedia

class StoryCreatorViewModel: ObservableObject {
    @Published var imageSelection: [PhotosPickerItem] = []

    func createStory(media: UIImage) {
        FirebaseManager.shared.createPost(media: [media], mediaType: .story, caption: "") { result in
            switch result {
            case .success(let story):
                print("Successfully created story with ID: \(story.id ?? "")")
            case .failure(let error):
                print("Failed to create story: \(error)")
            }
        }
    }
    
    func createVideoStory(videoURL: URL) {
        let videoAsset = AVAsset(url: videoURL)
        let exportSession = AVAssetExportSession(asset: videoAsset, presetName: AVAssetExportPresetMediumQuality)
        exportSession?.outputFileType = .mp4
        exportSession?.outputURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mp4")
        
        exportSession?.exportAsynchronously {
            guard let outputURL = exportSession?.outputURL else { return }
            switch exportSession?.status {
            case .completed:
//                FirebaseManager.shared.createPost(media: [outputURL], mediaType: .story, caption: "") { result in
//                    switch result {
//                    case .success(let story):
//                        print("Successfully created video story with ID: \(story.id ?? "")")
//                    case .failure(let error):
//                        print("Failed to create video story: \(error)")
//                    }
//                }
                print("Succeeded to export video")

            case .failed, .cancelled, .unknown, .waiting, .exporting, .none:
                print("Failed to export video")
            }
        }
    }
}

struct StoryCreatorView: View {
    @Environment(\.presentationMode) var presentationMode
    @StateObject private var viewModel = StoryCreatorViewModel()

    @State private var media: UIImage?
    @State private var isVideoRecording = false
    @State private var videoURL: URL?
    @State private var showImagePicker = false

    private var cameraView = CameraView()

    var body: some View {
        ZStack {
            cameraView
                .edgesIgnoringSafeArea(.all)

            VStack {
                Spacer()

                HStack {
                    Button(action: {
                        showImagePicker.toggle()
                    }) {
                        PhotosPicker(selection: $viewModel.imageSelection, maxSelectionCount: 1, matching: .images) {
                            Image(systemName: "photo")
                                .font(.system(size: 25))
                        }
                        .onChange(of: viewModel.imageSelection) { items in
                            Task {
                                if let item = items.first,
                                    let data = try? await item.loadTransferable(type: Data.self),
                                    let image = UIImage(data: data) {
                                        DispatchQueue.main.async {
                                            media = image
                                        }
                                }
                            }
                        }
                    }
                    .padding()

                    Spacer()

                    Button(action: {
                        if let media = media {
                            viewModel.createStory(media: media)
                            presentationMode.wrappedValue.dismiss()
                        } else if let videoURL = videoURL {
                            viewModel.createVideoStory(videoURL: videoURL)
                            presentationMode.wrappedValue.dismiss()
                        }
                    }) {
                        Text("Post Story")
                    }
                    .padding()
                    .disabled(media == nil && videoURL == nil)
                }

                HStack {
                    Button(action: {
                        cameraView.switchCamera()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath.camera")
                            .font(.system(size: 25))
                    }
                    .padding()

                    Spacer()

                    Button(action: {
                        if !isVideoRecording {
                            cameraView.startRecording { url in
                                videoURL = url
                            }
                        } else {
                            cameraView.stopRecording()
                        }
                        isVideoRecording.toggle()
                    }) {
                        Image(systemName: isVideoRecording ? "stop.fill" : "circle.fill")
                            .font(.system(size: 80))
                    }
                    .padding()
                }
            }
        }
    }
}


struct CameraView: UIViewRepresentable {
    let captureSession = AVCaptureSession()
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let movieFileOutput = AVCaptureMovieFileOutput()

        func makeUIView(context: Context) -> UIView {
            let previewView = UIView(frame: UIScreen.main.bounds)
            let previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            previewLayer.videoGravity = .resizeAspectFill
            previewLayer.frame = previewView.frame
            previewView.layer.addSublayer(previewLayer)
                        
            setUpCaptureSession()

            return previewView
        }

        func updateUIView(_ uiView: UIView, context: Context) {}

        private func setUpCaptureSession() {
            captureSession.sessionPreset = .medium
            addCameraInput()
            
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession.startRunning()
            }
        }

    private func addCameraInput() {
        if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
               if let deviceInput = try? AVCaptureDeviceInput(device: device) {
                   if captureSession.canAddInput(deviceInput) {
                       captureSession.addInput(deviceInput)
                   }
               }
           }
       }

       func switchCamera() {
           captureSession.beginConfiguration()
           if let currentInput = captureSession.inputs.first as? AVCaptureDeviceInput {
               captureSession.removeInput(currentInput)
               var cameraPosition: AVCaptureDevice.Position = .back
               cameraPosition = (cameraPosition == .back) ? .front : .back
               addCameraInput()
           }
           captureSession.commitConfiguration()
       }

       func startRecording(completion: @escaping (URL) -> Void) {
           if !movieFileOutput.isRecording, let connection = movieFileOutput.connection(with: .video) {
               connection.videoOrientation = .portrait
               let temporaryFileURL = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".mov")
               movieFileOutput.startRecording(to: temporaryFileURL, recordingDelegate: makeCoordinator())
               makeCoordinator().recordingStarted = {
                   DispatchQueue.main.async {
                       completion(temporaryFileURL)
                   }
               }
           }
       }

       func stopRecording() {
           if movieFileOutput.isRecording {
               movieFileOutput.stopRecording()
           }
       }

       func makeCoordinator() -> Coordinator {
           let coordinator = Coordinator()
           coordinator.delegate = self
           return coordinator
       }

       class Coordinator: NSObject, AVCaptureFileOutputRecordingDelegate {
           var delegate: CameraView?
           var recordingStarted: (() -> Void)?

           func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
               recordingStarted?()
           }

           func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
               // Handle video recording completion if needed
           }
       }
}

