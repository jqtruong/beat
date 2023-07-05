use std::sync::Arc;

use bytemuck::{Pod, Zeroable};
use vulkano::buffer::{BufferUsage, CpuAccessibleBuffer, TypedBufferAccess};
use vulkano::command_buffer::{
    AutoCommandBufferBuilder, CommandBufferUsage, PrimaryAutoCommandBuffer, RenderPassBeginInfo,
    SubpassContents,
};
use vulkano::device::physical::{PhysicalDevice, PhysicalDeviceType, QueueFamily};
use vulkano::device::{Device, DeviceCreateInfo, DeviceExtensions, Queue, QueueCreateInfo};
use vulkano::image::view::ImageView;
use vulkano::image::{ImageUsage, SwapchainImage};
use vulkano::instance::{Instance, InstanceCreateInfo};
use vulkano::pipeline::graphics::input_assembly::InputAssemblyState;
use vulkano::pipeline::graphics::vertex_input::BuffersDefinition;
use vulkano::pipeline::graphics::viewport::{Viewport, ViewportState};
use vulkano::pipeline::GraphicsPipeline;
use vulkano::render_pass::{Framebuffer, FramebufferCreateInfo, RenderPass, Subpass};
use vulkano::shader::ShaderModule;
use vulkano::swapchain::{
    self, AcquireError, Surface, Swapchain, SwapchainCreateInfo, SwapchainCreationError,
};
use vulkano::sync::{self, FenceSignalFuture, FlushError, GpuFuture};
use vulkano_win::VkSurfaceBuild;
use winit::event::{Event, WindowEvent};
use winit::event_loop::{ControlFlow, EventLoop};
use winit::window::{Window, WindowBuilder};

#[repr(C)]
#[derive(Default, Copy, Clone, Zeroable, Pod)]
struct Vertex {
    position: [f32; 2],
}

fn get_framebuffers(
    images: &[Arc<SwapchainImage<Window>>],
    render_pass: Arc<RenderPass>,
) -> Vec<Arc<Framebuffer>> {
    images
        .iter()
        .map(|image| {
            let view = ImageView::new_default(image.clone()).unwrap();
            Framebuffer::new(
                render_pass.clone(),
                FramebufferCreateInfo {
                    attachments: vec![view],
                    ..Default::default()
                },
            )
            .unwrap()
        })
        .collect::<Vec<_>>()
}

fn get_render_pass(device: Arc<Device>, swapchain: Arc<Swapchain<Window>>) -> Arc<RenderPass> {
    // "draw some color to a single image..."
    vulkano::single_pass_renderpass!(
        device.clone(),
        attachments: {
            color: {
                load: Clear, // want to clear on load
                store: Store, // want to store the image on the GPU
                format: swapchain.image_format(),  // set the format the same as the swapchain
                samples: 1,
            }
        },
        pass: {
            color: [color],
            depth_stencil: {}
        }
    )
    .unwrap()
}

// 'a is a lifetime annoation
pub fn select_physical_device<'a>(
    instance: &'a Arc<Instance>,
    surface: Arc<Surface<Window>>,
    device_extensions: &DeviceExtensions,
) -> (PhysicalDevice<'a>, QueueFamily<'a>) {
    // enumarate(collect?) the physical devices from the instance
    let (physical_device, queue_family) = PhysicalDevice::enumerate(&instance)
        // device must support swapchains; why using the reference symbol here but not when getting
        // its queue families?
        .filter(|&p| p.supported_extensions().is_superset_of(&device_extensions))
        .filter_map(|p| {
            p.queue_families()
                // family must support the graphics pipeline; not sure about what's special about
                // the surface but must support that too
                .find(|&q| q.supports_graphics() && q.supports_surface(&surface).unwrap_or(false))
                .map(|q| (p, q))
        })
        // typically want a GPU so check the device's type
        .min_by_key(|(p, _)| match p.properties().device_type {
            PhysicalDeviceType::DiscreteGpu => 0,
            PhysicalDeviceType::IntegratedGpu => 1,
            PhysicalDeviceType::VirtualGpu => 2,
            PhysicalDeviceType::Cpu => 3,
            PhysicalDeviceType::Other => 4,
        })
        // this is a bit counter-intuitive but it will send that error message is it didn't get
        // anything
        .expect("no device available");

    // returns a tuple
    (physical_device, queue_family)
}

fn main() {
    // to create a window, Vulkan requires extra extensions, provided by vulkano_win
    let required_extensions = vulkano_win::required_extensions();
    // create a new instance with the window requirements
    let instance = Instance::new(InstanceCreateInfo {
        enabled_extensions: required_extensions,
        ..Default::default()
    })
    .expect("failed to create instance");

    // the event loop will be executed at the end of main
    let event_loop = EventLoop::new();

    // create a surface with the event loop
    let surface = WindowBuilder::new()
        .build_vk_surface(&event_loop, instance.clone())
        .unwrap();
    // println!("{:#?}", surface);
    /*
     * surface knows that i'm using Wayland, but it doesn't have swapchains...
     *
     *     ...
     *     has_swapchain: false,
     *
     *  ...until it's created just a bit later
     */

    // require that the device is capable of swapchains
    let device_extensions = DeviceExtensions {
        khr_swapchain: true,
        ..DeviceExtensions::none()
    };

    // physical device requires the instance, surface, and extensions
    let (physical_device, queue_family) =
        select_physical_device(&instance, surface.clone(), &device_extensions);
    // println!("{:#?}", physical_device);
    /*
     * nano x1 has an intel integrated gpu,
     * named "Intel(R) Xe Graphics (TGL GT2)",
     * supports swapchains:
     */

    // create another representation of the physical device, not sure what queue is about...
    let (device, mut queues) = Device::new(
        physical_device,
        DeviceCreateInfo {
            queue_create_infos: vec![QueueCreateInfo::family(queue_family)],
            enabled_extensions: device_extensions, // new
            ..Default::default()
        },
    )
    .expect("failed to create device");

    let queue = queues.next().unwrap();
    // println!("{:#?}", queue);
    /*
     * the queue seems to have the same keys/values as the info of a physical device, except for
     * what is supported by the latter, and enabled by the former, e.g.:
     *
     *     enabled_extensions: [VK_KHR_swapchain],
     *     ...
     */

    let (mut swapchain, images) = {
        let caps = physical_device
            .surface_capabilities(&surface, Default::default())
            .expect("failed to get surface capabilities");
        // println!("{:#?}", caps);
        /*
         * not a lot of capabilities supported on this GPU.
         * 4 images minimum; as in for swapping?
         */

        let dimensions = surface.window().inner_size();
        // println!("{:#?}", dimensions);
        /*
         * PhysicalSize {
         *     width: 800,
         *     height: 600,
         * }
         */

        let composite_alpha = caps.supported_composite_alpha.iter().next().unwrap();
        // println!("{:#?}", composite_alpha);
        /*
         * Opaque
         */

        let image_format = Some(
            physical_device
                .surface_formats(&surface, Default::default())
                .unwrap()[0]
                .0,
        );
        // println!("{:#?}", image_format);
        /*
         * Some(
         *     A2R10G10B10_UNORM_PACK32,
         * )
         */

        // the `surface` will update its `has_swapchain` to `true` during this call
        Swapchain::new(
            device.clone(),
            surface.clone(),
            SwapchainCreateInfo {
                min_image_count: caps.min_image_count,
                image_format,
                image_extent: dimensions.into(),
                image_usage: ImageUsage::color_attachment(),
                composite_alpha,
                ..Default::default()
            },
        )
        .unwrap()
    };
    // println!("{:#?}", swapchain);
    // println!("{:#?}", images);
    /*
     * lots of data there that seems to be from previous objects, as well as nested and duplicated
     * ones, like images.
     */

    // to contain descriptions about the attachments and passes
    let render_pass = get_render_pass(device.clone(), swapchain.clone());

    // to contain info on each image's render pass actual attachment data, like an image view
    let framebuffers = get_framebuffers(&images, render_pass.clone());

    vulkano::impl_vertex!(Vertex, position);
}
