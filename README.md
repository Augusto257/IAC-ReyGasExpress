# Infraestructura para ReyGasExpress

## A. Integrantes:
- Ruiz Sanchez Fabricio Augusto.
- Vilchez Zavaleta Edwin Valentino.

## B. Descripción del Proyecto:

**ReyGasExpress** es un sistema integral diseñado para optimizar la gestión de pedidos de "REY GAS EXPRESS", una empresa distribuidora de gas y agua en Trujillo. La plataforma centraliza el registro eficiente de pedidos, capturando detalles cruciales como la ubicación del cliente y las marcas específicas solicitadas de gas y agua.

La funcionalidad clave de **ReyGasExpress** radica en su capacidad para analizar las preferencias de marca por sector geográfico dentro de la ciudad de Trujillo. Al identificar las marcas de gas y agua con mayor demanda en cada zona, el sistema proporciona información valiosa para la optimización de inventarios y la anticipación de la demanda por marca en cada sector.

El objetivo final de **ReyGasExpress** es mejorar significativamente la eficiencia operativa de "REY GAS EXPRESS" y aumentar la satisfacción del cliente, asegurando la disponibilidad de las marcas preferidas en cada área de Trujillo. Adicionalmente, el sistema facilitará la gestión de los pedidos diarios a los proveedores, basándose en la demanda anticipada.

La arquitectura de la plataforma se está desarrollando con un enfoque en la escalabilidad, la seguridad y el bajo mantenimiento.

## C. Servicios AWS Utilizados:

Este proyecto utiliza los siguientes servicios de Amazon Web Services (AWS) para construir una infraestructura robusta y escalable, enfocada en una arquitectura sin servidor (serverless) y de bajo mantenimiento:

-   **AWS WAF (Web Application Firewall):**
    * **Función en ReyGasExpress:** Protege la **API Gateway** de ReyGasExpress contra ataques web comunes como inyecciones SQL y scripts entre sitios, filtrando el tráfico malicioso y mejorando la seguridad de la aplicación.

-   **Amazon S3 (Simple Storage Service):**
    * **Función en ReyGasExpress:** Se utiliza para múltiples propósitos:
        * **Alojamiento del Frontend:** Sirve como host para los archivos estáticos (HTML, CSS, JavaScript) de la interfaz de usuario web.
        * **Almacenamiento de Datos:** Guarda reportes generados y datos intermedios de análisis de preferencias.
        * **Backend de Estado de Terraform:** Almacena de forma segura y versionada el archivo `terraform.tfstate` para gestionar la infraestructura como código.

-   **Amazon CloudFront:**
    * **Función en ReyGasExpress:** Actúa como una red de entrega de contenido (CDN) que distribuye el frontend web alojado en S3. Mejora la experiencia del usuario al entregar contenido con baja latencia y alta velocidad, utilizando ubicaciones de borde (Edge Locations) cercanas a los usuarios.

-   **Amazon API Gateway:**
    * **Función en ReyGasExpress:** Es el punto de entrada unificado y seguro para todas las solicitudes entrantes de la aplicación. Gestiona el enrutamiento de las solicitudes a las funciones **AWS Lambda** correspondientes y aplica mecanismos de autenticación y autorización.

-   **AWS Lambda:**
    * **Función en ReyGasExpress:** Es el corazón de la lógica de negocio sin servidor. Múltiples funciones Lambda se encargan de tareas específicas como:
        * `Registrar Pedido`
        * `Procesar Pedido`
        * `Analizar Preferencias`
        * `Generar Reporte de Preferencias`
        * `Enviar Reporte por Correo Electrónico`

-   **Amazon VPC (Virtual Private Cloud):**
    * **Función en ReyGasExpress:** Proporciona un entorno de red aislado y seguro en la nube. Aloja recursos de backend como la base de datos **Amazon RDS**, permitiendo un control granular sobre la conectividad y la seguridad de la red.

-   **Amazon Cognito:**
    * **Función en ReyGasExpress:** Gestiona la autenticación y autorización de los usuarios de la aplicación. Permite el registro seguro, el inicio de sesión y el control de acceso a los recursos de la **API Gateway**.

-   **AWS IAM (Identity and Access Management):**
    * **Función en ReyGasExpress:** Define y gestiona los permisos y roles de todos los servicios y usuarios de AWS involucrados en ReyGasExpress, asegurando el principio de mínimo privilegio y una interacción segura entre los componentes.

-   **Amazon CloudWatch:**
    * **Función en ReyGasExpress:** Es el servicio central de monitoreo y observabilidad. Recopila métricas, logs y eventos de todos los servicios de ReyGasExpress, permitiendo el monitoreo del rendimiento, la salud de la aplicación y el diagnóstico de problemas a través de dashboards personalizados y alarmas.

-   **Amazon RDS (Relational Database Service):**
    * **Función en ReyGasExpress:** Aloja la base de datos relacional (por ejemplo, PostgreSQL o MySQL) de la aplicación, donde se almacena la información crítica de pedidos, clientes y datos transaccionales, proporcionando escalabilidad y alta disponibilidad.

-   **Amazon EventBridge:**
    * **Función en ReyGasExpress:** Sirve como un bus de eventos sin servidor que facilita la comunicación asíncrona entre los componentes de la aplicación. Se utiliza para orquestar flujos de trabajo basados en eventos, como disparar análisis de preferencias o la generación de reportes programados.

-   **Amazon SNS (Simple Notification Service):**
    * **Función en ReyGasExpress:** Un servicio de mensajería de publicación/suscripción. En ReyGasExpress, puede usarse para notificar a suscriptores sobre eventos importantes o para disparar procesos subsiguientes, como la invocación de funciones Lambda para el envío de correos.

-   **Amazon SES (Simple Email Service):**
    * **Función en ReyGasExpress:** Un servicio de envío de correos electrónicos. Se encarga de enviar los reportes de preferencias generados automáticamente a los correos electrónicos designados, como los dueños del negocio.

## D. Requisitos Previos:

Antes de desplegar la infraestructura, asegúrate de tener instalados y configurados los siguientes:

-   **AWS CLI:** Configurado con credenciales de una cuenta AWS que tenga permisos suficientes para crear y gestionar los recursos listados.
-   **Terraform CLI:** Versión 1.0 o superior.
-   **Credenciales AWS:** Asegurarse de que las credenciales de AWS ( `AWS_ACCESS_KEY_ID` y `AWS_SECRET_ACCESS_KEY`) estén configuradas en las variables de entorno o a través de Jenkins Credentials para el pipeline.